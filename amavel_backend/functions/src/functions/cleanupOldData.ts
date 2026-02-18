/**
 * Scheduled Cloud Function: Cleanup Old Data
 * Runs weekly on Sundays at 3:00 AM UTC (respecting GDPR data retention policies)
 * Deletes old conversation data, resolved alerts, and audio files based on user preferences
 */

import * as functions from 'firebase-functions';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';
import {
  getActiveUsers,
  getUserDataRetentionPreferences,
  deleteDocumentsBatch,
  getResolvedAlertsOlderThan
} from '../utils/firestore_helpers';

interface CleanupStats {
  usersProcessed: number;
  conversationTurnsDeleted: number;
  alertsDeleted: number;
  audioFilesDeleted: number;
  startTime: Date;
  endTime: Date;
  durationMs: number;
}

export const cleanupOldData = functions
  .region('europe-west1')
  .pubsub.schedule('0 3 * * 0') // Sunday at 3:00 AM UTC
  .timeZone('UTC')
  .onRun(async context => {
    const startTime = new Date();
    logger.info('Starting cleanup of old data');

    const stats: CleanupStats = {
      usersProcessed: 0,
      conversationTurnsDeleted: 0,
      alertsDeleted: 0,
      audioFilesDeleted: 0,
      startTime: startTime,
      endTime: new Date(),
      durationMs: 0
    };

    try {
      const db = admin.firestore();
      const storage = admin.storage();

      // Get all users with accounts
      const usersSnapshot = await db.collection('users').select('id').get();
      const userIds = usersSnapshot.docs.map(doc => doc.id);

      logger.info(`Processing cleanup for ${userIds.length} users`);

      // Process each user
      for (const userId of userIds) {
        try {
          const retentionPrefs = await getUserDataRetentionPreferences(userId);

          // Skip if user has disabled auto-delete
          if (!retentionPrefs.autoDelete) {
            logger.info(`Skipping cleanup for user ${userId} (auto-delete disabled)`);
            continue;
          }

          const retentionDays = retentionPrefs.retentionDays;

          // Delete old conversation turns
          const conversationTurnsDeleted = await deleteOldConversationTurns(
            userId,
            retentionDays
          );
          stats.conversationTurnsDeleted += conversationTurnsDeleted;

          // Delete old resolved alerts
          const alertsDeleted = await deleteOldResolvedAlerts(userId, retentionDays * 2);
          stats.alertsDeleted += alertsDeleted;

          // Delete old audio files from Storage
          const audioFilesDeleted = await deleteOldAudioFiles(userId, 30);
          stats.audioFilesDeleted += audioFilesDeleted;

          stats.usersProcessed++;

          logger.info(`Cleanup completed for user ${userId}`, {
            conversationTurnsDeleted,
            alertsDeleted,
            audioFilesDeleted
          });
        } catch (userError) {
          logger.error(`Error during cleanup for user ${userId}: ${userError}`);
          // Continue with next user
        }
      }

      // Write cleanup statistics to Firestore for monitoring
      stats.endTime = new Date();
      stats.durationMs = stats.endTime.getTime() - stats.startTime.getTime();

      await db.collection('system').doc('cleanup_stats').set(
        {
          lastCleanup: admin.firestore.Timestamp.now(),
          stats: {
            usersProcessed: stats.usersProcessed,
            conversationTurnsDeleted: stats.conversationTurnsDeleted,
            alertsDeleted: stats.alertsDeleted,
            audioFilesDeleted: stats.audioFilesDeleted,
            durationMs: stats.durationMs
          }
        },
        { merge: true }
      );

      logger.info('Cleanup of old data completed successfully', {
        usersProcessed: stats.usersProcessed,
        conversationTurnsDeleted: stats.conversationTurnsDeleted,
        alertsDeleted: stats.alertsDeleted,
        audioFilesDeleted: stats.audioFilesDeleted,
        durationMs: stats.durationMs
      });
    } catch (error) {
      logger.error(`Fatal error during cleanup: ${error}`);
      throw error;
    }
  });

/**
 * Delete conversation turns older than specified days
 */
async function deleteOldConversationTurns(userId: string, days: number): Promise<number> {
  try {
    const db = admin.firestore();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    // Query for old conversation turns
    const snapshot = await db
      .collection('users')
      .doc(userId)
      .collection('conversations')
      .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(cutoffDate))
      .select('id')
      .get();

    if (snapshot.empty) {
      return 0;
    }

    const docIds = snapshot.docs.map(doc => doc.id);
    const collectionPath = `users/${userId}/conversations`;

    // Delete in batches of 100
    let deletedCount = 0;
    for (let i = 0; i < docIds.length; i += 100) {
      const batch = db.batch();
      const batchIds = docIds.slice(i, i + 100);

      batchIds.forEach(docId => {
        const docRef = db.collection('users').doc(userId).collection('conversations').doc(docId);
        batch.delete(docRef);
      });

      await batch.commit();
      deletedCount += batchIds.length;
    }

    logger.info(`Deleted ${deletedCount} conversation turns for user ${userId}`, {
      olderThanDays: days
    });

    return deletedCount;
  } catch (error) {
    logger.error(`Error deleting conversation turns for user ${userId}: ${error}`);
    return 0;
  }
}

/**
 * Delete resolved alerts older than specified days
 */
async function deleteOldResolvedAlerts(userId: string, days: number): Promise<number> {
  try {
    const db = admin.firestore();
    const alertIds = await getResolvedAlertsOlderThan(userId, days);

    if (alertIds.length === 0) {
      return 0;
    }

    let deletedCount = 0;
    for (let i = 0; i < alertIds.length; i += 100) {
      const batch = db.batch();
      const batchIds = alertIds.slice(i, i + 100);

      batchIds.forEach(alertId => {
        const alertRef = db.collection('users').doc(userId).collection('alerts').doc(alertId);
        batch.delete(alertRef);
      });

      await batch.commit();
      deletedCount += batchIds.length;
    }

    logger.info(`Deleted ${deletedCount} resolved alerts for user ${userId}`, {
      olderThanDays: days
    });

    return deletedCount;
  } catch (error) {
    logger.error(`Error deleting resolved alerts for user ${userId}: ${error}`);
    return 0;
  }
}

/**
 * Delete old audio files from Storage
 */
async function deleteOldAudioFiles(userId: string, days: number): Promise<number> {
  try {
    const storage = admin.storage();
    const bucket = storage.bucket();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    let deletedCount = 0;

    // List all audio files for this user
    const [files] = await bucket.getFiles({
      prefix: `audio/${userId}/`
    });

    for (const file of files) {
      try {
        // Get file metadata
        const [metadata] = await file.getMetadata();

        if (metadata.timeCreated) {
          const fileDate = new Date(metadata.timeCreated);
          if (fileDate < cutoffDate) {
            await file.delete();
            deletedCount++;
            logger.info(`Deleted old audio file: ${file.name}`);
          }
        }
      } catch (fileError) {
        logger.warn(`Error processing audio file ${file.name}: ${fileError}`);
      }
    }

    logger.info(`Deleted ${deletedCount} audio files for user ${userId}`, {
      olderThanDays: days
    });

    return deletedCount;
  } catch (error) {
    logger.error(`Error deleting audio files for user ${userId}: ${error}`);
    return 0;
  }
}

export default cleanupOldData;
