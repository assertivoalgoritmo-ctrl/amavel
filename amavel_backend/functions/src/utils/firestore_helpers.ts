/**
 * Firestore Helpers Utility
 * Common Firestore operations and query helpers
 */

import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';

/**
 * Get all family members for a user with their details
 */
export async function getFamilyMembers(
  userId: string
): Promise<Array<{ uid: string; email: string; name: string; relationship: string; fcmToken?: string }>> {
  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return [];
    }

    const familyMembers = userDoc.data()?.familyMembers || {};
    const result = [];

    for (const [uid, memberData] of Object.entries(familyMembers)) {
      const memberDoc = await db.collection('users').doc(uid).get();
      if (memberDoc.exists) {
        const member = memberDoc.data();
        result.push({
          uid: uid,
          email: member?.email || '',
          name: member?.name || 'Unknown',
          relationship: (memberData as any)?.relationship || 'family',
          fcmToken: member?.fcmTokens?.[0] // Get first token
        });
      }
    }

    return result;
  } catch (error) {
    logger.error(`Failed to get family members for user ${userId}: ${error}`);
    return [];
  }
}

/**
 * Get primary contact (usually first family member or specific role)
 */
export async function getPrimaryContact(userId: string): Promise<{
  uid: string;
  email: string;
  name: string;
  fcmToken?: string;
} | null> {
  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return null;
    }

    const familyMembers = userDoc.data()?.familyMembers || {};
    const primaryContactId = userDoc.data()?.primaryContact;

    // Try to find primary contact
    let contactUid = primaryContactId;

    // If no primary contact set, use first family member
    if (!contactUid) {
      contactUid = Object.keys(familyMembers)[0];
    }

    if (!contactUid) {
      return null;
    }

    const contactDoc = await db.collection('users').doc(contactUid).get();
    if (!contactDoc.exists) {
      return null;
    }

    const contact = contactDoc.data();
    return {
      uid: contactUid,
      email: contact?.email || '',
      name: contact?.name || 'Unknown',
      fcmToken: contact?.fcmTokens?.[0]
    };
  } catch (error) {
    logger.error(`Failed to get primary contact for user ${userId}: ${error}`);
    return null;
  }
}

/**
 * Create an alert in Firestore
 */
export async function createAlert(
  userId: string,
  severity: 'critical' | 'high' | 'medium' | 'low',
  title: string,
  description: string,
  metadata?: Record<string, any>
): Promise<string> {
  try {
    const db = admin.firestore();
    const alertRef = db.collection('users').doc(userId).collection('alerts').doc();

    const alertData = {
      id: alertRef.id,
      userId: userId,
      severity: severity,
      title: title,
      description: description,
      metadata: metadata || {},
      createdAt: admin.firestore.Timestamp.now(),
      resolved: false,
      resolvedAt: null,
      notificationSentAt: null
    };

    await alertRef.set(alertData);
    logger.info(`Alert created: ${alertRef.id}`, {
      userId,
      severity,
      title
    });

    return alertRef.id;
  } catch (error) {
    logger.error(`Failed to create alert for user ${userId}: ${error}`);
    throw error;
  }
}

/**
 * Update alert notification sent timestamp
 */
export async function updateAlertNotificationSent(
  userId: string,
  alertId: string
): Promise<void> {
  try {
    const db = admin.firestore();
    await db
      .collection('users')
      .doc(userId)
      .collection('alerts')
      .doc(alertId)
      .update({
        notificationSentAt: admin.firestore.Timestamp.now()
      });
  } catch (error) {
    logger.error(`Failed to update alert notification timestamp: ${error}`);
  }
}

/**
 * Get active users (users with recent activity)
 */
export async function getActiveUsers(): Promise<string[]> {
  try {
    const db = admin.firestore();
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const snapshot = await db
      .collection('users')
      .where('lastActivity', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .select('id')
      .get();

    return snapshot.docs.map(doc => doc.id);
  } catch (error) {
    logger.error(`Failed to get active users: ${error}`);
    return [];
  }
}

/**
 * Get conversation turns for aggregation
 */
export async function getConversationTurns(
  userId: string,
  startDate: Date,
  endDate: Date,
  limit?: number
): Promise<any[]> {
  try {
    const db = admin.firestore();
    let query = db
      .collection('users')
      .doc(userId)
      .collection('conversations')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
      .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(endDate));

    if (limit) {
      query = query.limit(limit);
    }

    const snapshot = await query.get();
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    logger.error(`Failed to get conversation turns for user ${userId}: ${error}`);
    return [];
  }
}

/**
 * Get resolved alerts older than specified days
 */
export async function getResolvedAlertsOlderThan(
  userId: string,
  days: number
): Promise<string[]> {
  try {
    const db = admin.firestore();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const snapshot = await db
      .collection('users')
      .doc(userId)
      .collection('alerts')
      .where('resolved', '==', true)
      .where('resolvedAt', '<=', admin.firestore.Timestamp.fromDate(cutoffDate))
      .select('id')
      .get();

    return snapshot.docs.map(doc => doc.id);
  } catch (error) {
    logger.error(`Failed to get old resolved alerts for user ${userId}: ${error}`);
    return [];
  }
}

/**
 * Delete batch of documents
 */
export async function deleteDocumentsBatch(
  collectionPath: string,
  documentIds: string[],
  batchSize: number = 100
): Promise<number> {
  let deletedCount = 0;

  try {
    const db = admin.firestore();

    for (let i = 0; i < documentIds.length; i += batchSize) {
      const batch = db.batch();
      const batchIds = documentIds.slice(i, i + batchSize);

      batchIds.forEach(docId => {
        const docRef = db.doc(collectionPath + '/' + docId);
        batch.delete(docRef);
      });

      await batch.commit();
      deletedCount += batchIds.length;
    }

    logger.info(`Deleted ${deletedCount} documents from ${collectionPath}`);
    return deletedCount;
  } catch (error) {
    logger.error(`Failed to delete documents: ${error}`);
    throw error;
  }
}

/**
 * Check user data retention preferences
 */
export async function getUserDataRetentionPreferences(userId: string): Promise<{
  retentionDays: number;
  autoDelete: boolean;
}> {
  try {
    const db = admin.firestore();
    const doc = await db.collection('users').doc(userId).collection('dataRetention').doc('config').get();

    if (doc.exists) {
      return {
        retentionDays: doc.data()?.retentionDays || 90,
        autoDelete: doc.data()?.autoDelete !== false
      };
    }

    return {
      retentionDays: 90,
      autoDelete: true
    };
  } catch (error) {
    logger.error(`Failed to get data retention preferences for user ${userId}: ${error}`);
    return {
      retentionDays: 90,
      autoDelete: true
    };
  }
}

/**
 * Calculate average sentiment from conversations
 */
export async function calculateAverageSentiment(
  userId: string,
  startDate: Date,
  endDate: Date
): Promise<number> {
  try {
    const conversations = await getConversationTurns(userId, startDate, endDate);

    if (conversations.length === 0) {
      return 0;
    }

    const sentiments = conversations
      .filter(conv => conv.sentiment !== undefined && conv.sentiment !== null)
      .map(conv => conv.sentiment as number);

    if (sentiments.length === 0) {
      return 0;
    }

    return sentiments.reduce((a, b) => a + b, 0) / sentiments.length;
  } catch (error) {
    logger.error(`Failed to calculate average sentiment for user ${userId}: ${error}`);
    return 0;
  }
}

/**
 * Get conversation topics discussed in period
 */
export async function getConversationTopics(
  userId: string,
  startDate: Date,
  endDate: Date,
  limit: number = 10
): Promise<string[]> {
  try {
    const conversations = await getConversationTurns(userId, startDate, endDate);

    const topics = new Set<string>();
    conversations.forEach(conv => {
      if (conv.topics && Array.isArray(conv.topics)) {
        conv.topics.forEach((topic: string) => topics.add(topic));
      }
    });

    return Array.from(topics).slice(0, limit);
  } catch (error) {
    logger.error(`Failed to get conversation topics for user ${userId}: ${error}`);
    return [];
  }
}

/**
 * Get unresolved alerts for user
 */
export async function getUnresolvedAlerts(userId: string): Promise<any[]> {
  try {
    const db = admin.firestore();
    const snapshot = await db
      .collection('users')
      .doc(userId)
      .collection('alerts')
      .where('resolved', '==', false)
      .orderBy('createdAt', 'desc')
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    logger.error(`Failed to get unresolved alerts for user ${userId}: ${error}`);
    return [];
  }
}

export default {
  getFamilyMembers,
  getPrimaryContact,
  createAlert,
  updateAlertNotificationSent,
  getActiveUsers,
  getConversationTurns,
  getResolvedAlertsOlderThan,
  deleteDocumentsBatch,
  getUserDataRetentionPreferences,
  calculateAverageSentiment,
  getConversationTopics,
  getUnresolvedAlerts
};
