/**
 * FCM Notification Sender Utility
 * Handles sending push notifications via Firebase Cloud Messaging
 */

import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  priority?: 'high' | 'normal';
  timeToLive?: number;
  sound?: string;
  badge?: string;
}

export interface AndroidConfig {
  priority?: 'high' | 'normal';
  notification?: {
    sound?: string;
    clickAction?: string;
    color?: string;
    icon?: string;
  };
}

/**
 * Send notification to a specific device token
 */
export async function sendToDevice(
  token: string,
  payload: NotificationPayload
): Promise<string> {
  try {
    const message: admin.messaging.Message = {
      token: token,
      notification: {
        title: payload.title,
        body: payload.body
      },
      data: payload.data || {},
      android: {
        priority: payload.priority || 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          color: '#6366F1' // Indigo color for AMAVEL
        }
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: payload.title,
              body: payload.body
            },
            sound: 'default',
            badge: 1,
            'mutable-content': 1
          }
        }
      }
    };

    const messageId = await admin.messaging().send(message);
    logger.info(`FCM sent to device ${token.substring(0, 20)}...`, {
      messageId,
      title: payload.title
    });
    return messageId;
  } catch (error) {
    logger.error(`Failed to send FCM to device: ${error}`, {
      token: token.substring(0, 20) + '...',
      payload
    });
    throw error;
  }
}

/**
 * Send notification to multiple device tokens
 */
export async function sendToMultipleDevices(
  tokens: string[],
  payload: NotificationPayload
): Promise<admin.messaging.BatchResponse> {
  try {
    const messages: admin.messaging.Message[] = tokens.map(token => ({
      token: token,
      notification: {
        title: payload.title,
        body: payload.body
      },
      data: payload.data || {},
      android: {
        priority: payload.priority || 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          color: '#6366F1'
        }
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: payload.title,
              body: payload.body
            },
            sound: 'default',
            badge: 1,
            'mutable-content': 1
          }
        }
      }
    }));

    const response = await admin.messaging().sendAll(messages);
    logger.info(`FCM batch sent to ${tokens.length} devices`, {
      successCount: response.successCount,
      failureCount: response.failureCount
    });

    // Handle failed tokens
    response.responses.forEach((resp, index) => {
      if (!resp.success) {
        logger.warn(`FCM failed for token ${tokens[index].substring(0, 20)}...`, {
          error: resp.error
        });
      }
    });

    return response;
  } catch (error) {
    logger.error(`Failed to send batch FCM: ${error}`, { tokensCount: tokens.length });
    throw error;
  }
}

/**
 * Send notification to a topic
 */
export async function sendToTopic(
  topic: string,
  payload: NotificationPayload
): Promise<string> {
  try {
    const message: admin.messaging.Message = {
      topic: topic,
      notification: {
        title: payload.title,
        body: payload.body
      },
      data: payload.data || {},
      android: {
        priority: payload.priority || 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          color: '#6366F1'
        }
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: payload.title,
              body: payload.body
            },
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    const messageId = await admin.messaging().send(message);
    logger.info(`FCM sent to topic ${topic}`, { messageId });
    return messageId;
  } catch (error) {
    logger.error(`Failed to send FCM to topic ${topic}: ${error}`);
    throw error;
  }
}

/**
 * Subscribe a device to a topic
 */
export async function subscribeToTopic(tokens: string[], topic: string): Promise<void> {
  try {
    await admin.messaging().subscribeToTopic(tokens, topic);
    logger.info(`Subscribed ${tokens.length} devices to topic ${topic}`);
  } catch (error) {
    logger.error(`Failed to subscribe to topic ${topic}: ${error}`);
    throw error;
  }
}

/**
 * Unsubscribe a device from a topic
 */
export async function unsubscribeFromTopic(tokens: string[], topic: string): Promise<void> {
  try {
    await admin.messaging().unsubscribeFromTopic(tokens, topic);
    logger.info(`Unsubscribed ${tokens.length} devices from topic ${topic}`);
  } catch (error) {
    logger.error(`Failed to unsubscribe from topic ${topic}: ${error}`);
    throw error;
  }
}

/**
 * Send alert notification with context
 */
export async function sendAlertNotification(
  recipientToken: string,
  alertType: 'critical' | 'high' | 'medium' | 'low',
  title: string,
  body: string,
  alertId: string,
  userId: string
): Promise<string> {
  const priorityMap = {
    critical: 'high' as const,
    high: 'high' as const,
    medium: 'normal' as const,
    low: 'normal' as const
  };

  return sendToDevice(recipientToken, {
    title: title,
    body: body,
    priority: priorityMap[alertType],
    data: {
      type: 'alert',
      severity: alertType,
      alertId: alertId,
      userId: userId
    }
  });
}

/**
 * Send message notification
 */
export async function sendMessageNotification(
  recipientToken: string,
  senderName: string,
  messagePreview: string,
  messageId: string,
  conversationId: string
): Promise<string> {
  return sendToDevice(recipientToken, {
    title: `Mensagem de ${senderName}`,
    body: messagePreview,
    priority: 'high',
    data: {
      type: 'message',
      messageId: messageId,
      conversationId: conversationId,
      senderName: senderName
    }
  });
}

/**
 * Handle FCM token update in Firestore
 */
export async function updateFCMToken(
  userId: string,
  token: string
): Promise<void> {
  try {
    const db = admin.firestore();
    const userRef = db.collection('users').doc(userId);

    await userRef.set(
      {
        fcmTokens: admin.firestore.FieldValue.arrayUnion([token]),
        lastTokenUpdate: admin.firestore.Timestamp.now()
      },
      { merge: true }
    );

    logger.info(`FCM token updated for user ${userId}`);
  } catch (error) {
    logger.error(`Failed to update FCM token: ${error}`);
    throw error;
  }
}

/**
 * Remove invalid FCM token from Firestore
 */
export async function removeFCMToken(
  userId: string,
  token: string
): Promise<void> {
  try {
    const db = admin.firestore();
    const userRef = db.collection('users').doc(userId);

    await userRef.set(
      {
        fcmTokens: admin.firestore.FieldValue.arrayRemove([token])
      },
      { merge: true }
    );

    logger.info(`FCM token removed for user ${userId}`);
  } catch (error) {
    logger.error(`Failed to remove FCM token: ${error}`);
    throw error;
  }
}

export default {
  sendToDevice,
  sendToMultipleDevices,
  sendToTopic,
  subscribeToTopic,
  unsubscribeFromTopic,
  sendAlertNotification,
  sendMessageNotification,
  updateFCMToken,
  removeFCMToken
};
