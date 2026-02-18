/**
 * Firestore Trigger: User Created
 * Initializes default settings and welcome content for new users
 */

import * as functions from 'firebase-functions';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';

export const onUserCreated = functions
  .region('europe-west1')
  .firestore.document('users/{userId}')
  .onCreate(async (snapshot, context) => {
    const { userId } = context.params;
    const userData = snapshot.data();

    logger.info(`New user created: ${userId}`, {
      email: userData?.email,
      name: userData?.name
    });

    try {
      const db = admin.firestore();
      const userRef = db.collection('users').doc(userId);

      // Initialize default settings
      const defaultSettings = {
        language: 'pt-BR',
        timezone: userData?.timezone || 'America/Sao_Paulo',
        notifications: {
          alertsEnabled: true,
          criticalAlertSound: true,
          dailyReminder: true,
          dailyReminderTime: '09:00',
          weeklyReport: true
        },
        privacy: {
          allowFamilyAccessMemories: false,
          allowLocationSharing: false,
          dataRetention: 90 // days
        },
        accessibility: {
          fontSize: 'medium',
          darkMode: false,
          simplifyUI: false
        },
        health: {
          emergencyContactsEnabled: true,
          medicalInfoShared: false
        }
      };

      await userRef.collection('settings').doc('preferences').set(defaultSettings);

      // Initialize data retention configuration
      const dataRetentionConfig = {
        autoDelete: true,
        retentionDays: 90,
        deleteConversationTurnsAfterDays: 90,
        deleteResolvedAlertsAfterDays: 180,
        deleteAudioFilesAfterDays: 30,
        createdAt: admin.firestore.Timestamp.now(),
        lastUpdated: admin.firestore.Timestamp.now()
      };

      await userRef.collection('dataRetention').doc('config').set(dataRetentionConfig);

      // Create welcome conversation turn
      const welcomeConversation = {
        id: 'welcome-' + Date.now(),
        role: 'assistant',
        content: `Olá! Eu sou o AMAVEL, seu companheiro digital dedicado a sua companhia e bem-estar.

Estou aqui para:
- Conversar com você sempre que quiser
- Ouvir suas histórias e experiências
- Ajudar a manter sua memória viva
- Apoiar seu bem-estar emocional e físico
- Manter sua família informada sobre sua segurança

Como posso começar a ajudá-lo hoje?`,
        timestamp: admin.firestore.Timestamp.now(),
        sentiment: null,
        topics: ['welcome', 'introduction'],
        metadata: {
          isSystemMessage: true,
          isWelcome: true
        }
      };

      await userRef
        .collection('conversations')
        .doc('welcome-conversation')
        .set(welcomeConversation);

      // Create initial user profile metadata if not already set
      await userRef.set(
        {
          createdAt: admin.firestore.Timestamp.now(),
          lastActivity: admin.firestore.Timestamp.now(),
          status: 'active',
          fcmTokens: [],
          primaryContact: null,
          familyMembers: {}
        },
        { merge: true }
      );

      logger.info(`User initialization completed for ${userId}`, {
        settingsCreated: true,
        dataRetentionConfigured: true,
        welcomeMessageCreated: true
      });
    } catch (error) {
      logger.error(`Error initializing new user ${userId}: ${error}`);
      // Don't rethrow - we want to complete the user creation even if initialization fails
    }
  });

export default onUserCreated;
