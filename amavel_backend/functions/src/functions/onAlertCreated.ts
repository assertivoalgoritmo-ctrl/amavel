/**
 * Firestore Trigger: Alert Created
 * Sends FCM notifications when a new alert is created
 * Severity levels: critical, high, medium, low
 */

import * as functions from 'firebase-functions';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';
import {
  sendToDevice,
  sendToMultipleDevices,
  updateFCMToken,
  removeFCMToken,
  sendAlertNotification
} from '../utils/fcm_sender';
import {
  getFamilyMembers,
  getPrimaryContact,
  updateAlertNotificationSent
} from '../utils/firestore_helpers';

interface AlertData {
  severity: 'critical' | 'high' | 'medium' | 'low';
  title: string;
  description: string;
  userId: string;
  createdAt: admin.firestore.Timestamp;
  metadata?: Record<string, any>;
}

export const onAlertCreated = functions
  .region('europe-west1')
  .firestore.document('users/{userId}/alerts/{alertId}')
  .onCreate(async (snapshot, context) => {
    const { userId, alertId } = context.params;
    const alertData = snapshot.data() as AlertData;

    logger.info(`Alert created for user ${userId}`, {
      alertId: alertId,
      severity: alertData.severity,
      title: alertData.title
    });

    try {
      // Get family members
      const familyMembers = await getFamilyMembers(userId);
      logger.info(`Found ${familyMembers.length} family members for user ${userId}`);

      // Critical alerts: send to all family members immediately
      if (alertData.severity === 'critical') {
        const tokens = familyMembers
          .filter(member => member.fcmToken)
          .map(member => member.fcmToken!);

        const familyNames = familyMembers.map(m => m.name).join(', ');

        const notificationTitle = 'Alerta Urgente do AMAVEL';
        const notificationBody = `${alertData.title}: ${alertData.description.substring(0, 80)}...`;

        if (tokens.length > 0) {
          try {
            await sendToMultipleDevices(tokens, {
              title: notificationTitle,
              body: notificationBody,
              priority: 'high',
              data: {
                type: 'alert',
                severity: 'critical',
                alertId: alertId,
                userId: userId,
                timestamp: new Date().toISOString()
              }
            });

            logger.info(`Sent critical alert to ${tokens.length} family members`, {
              familyNames,
              alertId
            });
          } catch (error) {
            logger.error(`Failed to send critical alert notifications: ${error}`, {
              alertId
            });
          }
        } else {
          logger.warn(`No FCM tokens available for family members of user ${userId}`);
        }
      }

      // High severity alerts: send to primary contact
      else if (alertData.severity === 'high') {
        const primaryContact = await getPrimaryContact(userId);

        if (primaryContact && primaryContact.fcmToken) {
          const notificationTitle = 'Alerta do AMAVEL';
          const notificationBody = `${alertData.title}: ${alertData.description.substring(0, 100)}...`;

          try {
            await sendAlertNotification(
              primaryContact.fcmToken,
              'high',
              notificationTitle,
              notificationBody,
              alertId,
              userId
            );

            logger.info(`Sent high severity alert to primary contact`, {
              contactName: primaryContact.name,
              alertId
            });
          } catch (error) {
            logger.error(`Failed to send high severity alert to primary contact: ${error}`, {
              alertId
            });

            // Handle invalid token
            if (
              error instanceof Error &&
              (error.message.includes('InvalidRegistrationToken') ||
                error.message.includes('NotRegistered'))
            ) {
              try {
                await removeFCMToken(primaryContact.uid, primaryContact.fcmToken);
              } catch (removeError) {
                logger.error(`Failed to remove invalid FCM token: ${removeError}`);
              }
            }
          }
        } else {
          logger.warn(`No primary contact or FCM token for user ${userId}`);
        }
      }

      // Medium and low severity alerts: will be aggregated in weekly wellness report
      else {
        logger.info(`Alert will be aggregated for weekly report`, {
          severity: alertData.severity,
          alertId
        });
      }

      // Update alert document with notification sent timestamp
      await updateAlertNotificationSent(userId, alertId);

      logger.info(`Alert notification processing completed for ${alertId}`);
    } catch (error) {
      logger.error(`Error processing alert created trigger: ${error}`, {
        userId,
        alertId
      });
      // Don't rethrow - we don't want to retry this trigger
    }
  });

export default onAlertCreated;
