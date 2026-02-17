/**
 * AMAVEL Cloud Functions
 * Main entry point for all Cloud Functions
 * Exports all triggers and scheduled functions
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import all Cloud Functions
import { onAlertCreated } from './functions/onAlertCreated';
import { onMessageCreated } from './functions/onMessageCreated';
import { onUserCreated } from './functions/onUserCreated';
import { cleanupOldData } from './functions/cleanupOldData';
import { generateWellnessReport } from './functions/generateWellnessReport';

// Export all Cloud Functions
export {
  // Firestore triggers
  onAlertCreated,
  onMessageCreated,
  onUserCreated,
  // Scheduled functions
  cleanupOldData,
  generateWellnessReport
};

// Export configuration and utilities for testing/external use
export { AMAVEL_SYSTEM_PROMPT } from './config/system_prompt';
export { GUARDRAILS_CONFIG, checkAlertSeverity, detectScamIndicators, detectMedicalRisks, detectAbuseIndicators } from './config/guardrails_config';
export { MEMORY_TOOLS, formatMemoryFacts, type MemoryFact } from './config/memory_tools';

export { sendToDevice, sendToMultipleDevices, sendToTopic, subscribeToTopic, unsubscribeFromTopic, sendAlertNotification, sendMessageNotification, updateFCMToken, removeFCMToken } from './utils/fcm_sender';
export {
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
} from './utils/firestore_helpers';
