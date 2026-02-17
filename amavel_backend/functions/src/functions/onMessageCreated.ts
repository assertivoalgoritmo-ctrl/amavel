/**
 * Firestore Trigger: Message Created
 * Sends FCM notification when a new message is received
 */

import * as functions from 'firebase-functions';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';
import {
  sendMessageNotification,
  sendToDevice,
  removeFCMToken
} from '../utils/fcm_sender';

interface MessageData {
  senderId: string;
  senderName: string;
  recipientId: string;
  content: string;
  transcript?: string;
  isVoiceMessage: boolean;
  createdAt: admin.firestore.Timestamp;
  conversationId?: string;
}

export const onMessageCreated = functions
  .region('europe-west1')
  .firestore.document('users/{userId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const { userId, messageId } = context.params;
    const messageData = snapshot.data() as MessageData;

    logger.info(`Message created for user ${userId}`, {
      messageId: messageId,
      from: messageData.senderName,
      isVoice: messageData.isVoiceMessage
    });

    try {
      // Get recipient's FCM token
      const db = admin.firestore();
      const recipientDoc = await db.collection('users').doc(userId).get();

      if (!recipientDoc.exists) {
        logger.warn(`Recipient user document not found: ${userId}`);
        return;
      }

      const recipientData = recipientDoc.data();
      const fcmTokens = recipientData?.fcmTokens || [];

      if (fcmTokens.length === 0) {
        logger.info(`No FCM tokens for recipient ${userId}`);
        return;
      }

      // Prepare message preview
      let messagePreview = '';

      if (messageData.isVoiceMessage) {
        // For voice messages, use transcript or indicate audio
        if (messageData.transcript) {
          messagePreview = messageData.transcript.substring(0, 100);
          if (messageData.transcript.length > 100) {
            messagePreview += '...';
          }
        } else {
          messagePreview = 'Mensagem de áudio';
        }
      } else {
        // For text messages, use content
        messagePreview = messageData.content.substring(0, 100);
        if (messageData.content.length > 100) {
          messagePreview += '...';
        }
      }

      // Prepare notification data
      const notificationData = {
        type: 'message',
        messageId: messageId,
        conversationId: messageData.conversationId || '',
        senderName: messageData.senderName,
        senderId: messageData.senderId,
        isVoice: messageData.isVoiceMessage ? 'true' : 'false'
      };

      // Send notification to each FCM token
      const sentTokens: string[] = [];
      const failedTokens: string[] = [];

      for (const token of fcmTokens) {
        try {
          await sendMessageNotification(
            token,
            messageData.senderName,
            messagePreview,
            messageId,
            messageData.conversationId || ''
          );

          sentTokens.push(token);
          logger.info(`Message notification sent to token ${token.substring(0, 20)}...`, {
            messageId
          });
        } catch (error) {
          logger.error(`Failed to send message notification to token: ${error}`, {
            messageId,
            token: token.substring(0, 20) + '...'
          });

          failedTokens.push(token);

          // If token is invalid, remove it
          if (
            error instanceof Error &&
            (error.message.includes('InvalidRegistrationToken') ||
              error.message.includes('NotRegistered') ||
              error.message.includes('invalid-argument'))
          ) {
            try {
              await removeFCMToken(userId, token);
              logger.info(`Removed invalid FCM token for user ${userId}`);
            } catch (removeError) {
              logger.error(`Failed to remove invalid FCM token: ${removeError}`);
            }
          }
        }
      }

      logger.info(`Message notification processing completed`, {
        messageId,
        sentCount: sentTokens.length,
        failedCount: failedTokens.length
      });
    } catch (error) {
      logger.error(`Error processing message created trigger: ${error}`, {
        userId,
        messageId
      });
      // Don't rethrow - we don't want to retry this trigger
    }
  });

export default onMessageCreated;
