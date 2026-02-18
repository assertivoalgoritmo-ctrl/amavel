/**
 * Scheduled Cloud Function: Generate Wellness Report
 * Runs weekly on Mondays at 9:00 AM UTC
 * Creates aggregated wellness summaries for each user and notifies their primary family contact
 */

import * as functions from 'firebase-functions';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';
import {
  getActiveUsers,
  getPrimaryContact,
  getConversationTurns,
  getUnresolvedAlerts,
  calculateAverageSentiment,
  getConversationTopics
} from '../utils/firestore_helpers';
import { sendToDevice } from '../utils/fcm_sender';

interface WellnessReport {
  userId: string;
  reportDate: Date;
  weekStartDate: Date;
  weekEndDate: Date;
  conversationCount: number;
  averageSentiment: number;
  distressAlertCount: number;
  highAlertCount: number;
  mediumAlertCount: number;
  topicsDiscussed: string[];
  overallWellness: 'excellent' | 'good' | 'fair' | 'concerning';
  summary: string;
}

export const generateWellnessReport = functions
  .region('europe-west1')
  .pubsub.schedule('0 9 * * 1') // Monday at 9:00 AM UTC
  .timeZone('UTC')
  .onRun(async context => {
    const reportDate = new Date();
    logger.info('Starting weekly wellness report generation');

    try {
      const db = admin.firestore();

      // Get all active users
      const userIds = await getActiveUsers();
      logger.info(`Generating reports for ${userIds.length} active users`);

      let reportsGenerated = 0;
      let notificationsSent = 0;

      // Process each user
      for (const userId of userIds) {
        try {
          // Calculate week date range
          const weekEndDate = new Date(reportDate);
          weekEndDate.setDate(weekEndDate.getDate() - 1); // Yesterday
          const weekStartDate = new Date(weekEndDate);
          weekStartDate.setDate(weekStartDate.getDate() - 6); // 7 days ago

          // Get conversation data for the week
          const conversations = await getConversationTurns(
            userId,
            weekStartDate,
            weekEndDate,
            500
          );

          // Get alert data for the week
          const allAlerts = await getUnresolvedAlerts(userId);
          const weekAlerts = allAlerts.filter(alert => {
            if (alert.createdAt) {
              const alertDate = alert.createdAt.toDate
                ? alert.createdAt.toDate()
                : new Date(alert.createdAt);
              return alertDate >= weekStartDate && alertDate <= weekEndDate;
            }
            return false;
          });

          // Calculate metrics
          const conversationCount = conversations.length;
          const averageSentiment = await calculateAverageSentiment(
            userId,
            weekStartDate,
            weekEndDate
          );
          const distressAlertCount = weekAlerts.filter(a => a.severity === 'critical').length;
          const highAlertCount = weekAlerts.filter(a => a.severity === 'high').length;
          const mediumAlertCount = weekAlerts.filter(a => a.severity === 'medium').length;
          const topicsDiscussed = await getConversationTopics(userId, weekStartDate, weekEndDate);

          // Determine overall wellness
          let overallWellness: 'excellent' | 'good' | 'fair' | 'concerning' = 'good';

          if (distressAlertCount > 2 || highAlertCount > 5) {
            overallWellness = 'concerning';
          } else if (highAlertCount > 2 || averageSentiment < 3) {
            overallWellness = 'fair';
          } else if (conversationCount > 10 && averageSentiment > 6) {
            overallWellness = 'excellent';
          }

          // Generate summary text in Portuguese
          const summary = generateWellnessSummary(
            conversationCount,
            averageSentiment,
            distressAlertCount,
            highAlertCount,
            mediumAlertCount,
            topicsDiscussed,
            overallWellness
          );

          // Create report document
          const report: WellnessReport = {
            userId: userId,
            reportDate: reportDate,
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            conversationCount: conversationCount,
            averageSentiment: averageSentiment,
            distressAlertCount: distressAlertCount,
            highAlertCount: highAlertCount,
            mediumAlertCount: mediumAlertCount,
            topicsDiscussed: topicsDiscussed,
            overallWellness: overallWellness,
            summary: summary
          };

          // Store report in Firestore
          const reportRef = db
            .collection('users')
            .doc(userId)
            .collection('wellnessReports')
            .doc(`report-${reportDate.getFullYear()}-W${getWeekNumber(reportDate)}`);

          await reportRef.set(report);
          reportsGenerated++;

          logger.info(`Wellness report generated for user ${userId}`, {
            conversationCount,
            averageSentiment: averageSentiment.toFixed(2),
            alertsCount: weekAlerts.length,
            overallWellness
          });

          // Send notification to primary family contact
          try {
            const primaryContact = await getPrimaryContact(userId);

            if (primaryContact && primaryContact.fcmToken) {
              const reportPreview =
                overallWellness === 'concerning'
                  ? `Relatório importante sobre ${primaryContact.name}`
                  : `Relatório semanal de ${primaryContact.name}`;

              await sendToDevice(primaryContact.fcmToken, {
                title: 'Relatório Semanal do AMAVEL',
                body: reportPreview,
                data: {
                  type: 'wellness_report',
                  userId: userId,
                  reportDate: reportDate.toISOString(),
                  wellness: overallWellness
                },
                priority: overallWellness === 'concerning' ? 'high' : 'normal'
              });

              notificationsSent++;
              logger.info(`Wellness report notification sent to ${primaryContact.name}`, {
                userId
              });
            }
          } catch (notificationError) {
            logger.warn(`Failed to send wellness report notification for user ${userId}`, {
              error: notificationError
            });
          }
        } catch (userError) {
          logger.error(`Error generating wellness report for user ${userId}: ${userError}`);
          // Continue with next user
        }
      }

      logger.info('Weekly wellness report generation completed', {
        reportsGenerated,
        notificationsSent
      });
    } catch (error) {
      logger.error(`Fatal error during wellness report generation: ${error}`);
      throw error;
    }
  });

/**
 * Generate wellness summary text in Portuguese
 */
function generateWellnessSummary(
  conversationCount: number,
  averageSentiment: number,
  distressAlertCount: number,
  highAlertCount: number,
  mediumAlertCount: number,
  topicsDiscussed: string[],
  overallWellness: string
): string {
  let summary = `Relatório Semanal do AMAVEL\n\n`;

  // Wellness statement
  const wellnessEmoji: Record<string, string> = {
    excellent: '✨ Excelente',
    good: '👍 Bom',
    fair: '⚠️ Razoável',
    concerning: '🚨 Preocupante'
  };

  summary += `Bem-estar geral: ${wellnessEmoji[overallWellness]}\n\n`;

  // Conversation metrics
  summary += `Atividade esta semana:\n`;
  summary += `• ${conversationCount} conversas\n`;
  summary += `• Sentimento médio: ${averageSentiment.toFixed(1)}/10\n`;

  // Alert summary
  if (distressAlertCount + highAlertCount + mediumAlertCount > 0) {
    summary += `\nAlertas detectados:\n`;
    if (distressAlertCount > 0) {
      summary += `• ${distressAlertCount} alerta(s) crítico(s)\n`;
    }
    if (highAlertCount > 0) {
      summary += `• ${highAlertCount} alerta(s) alto(s)\n`;
    }
    if (mediumAlertCount > 0) {
      summary += `• ${mediumAlertCount} alerta(s) médio(s)\n`;
    }
  } else {
    summary += `\nNenhum alerta desta semana. Tudo bem! 😊\n`;
  }

  // Topics discussed
  if (topicsDiscussed.length > 0) {
    summary += `\nTópicos discutidos:\n`;
    topicsDiscussed.slice(0, 5).forEach(topic => {
      summary += `• ${topic}\n`;
    });
  }

  // Recommendations
  summary += `\nPróximos passos:\n`;
  if (overallWellness === 'concerning') {
    summary += `• Considere entrar em contato para verificar como está\n`;
    summary += `• Alguns momentos dessa semana precisaram de atenção\n`;
  } else if (overallWellness === 'fair') {
    summary += `• Pode ser bom uma conversa mais longa essa semana\n`;
    summary += `• Alguns tópicos geraram preocupação\n`;
  } else {
    summary += `• Continue as atividades que estão funcionando bem\n`;
    summary += `• A conversa continua sendo muito importante\n`;
  }

  summary += `\nVisite o app AMAVEL para mais detalhes.`;

  return summary;
}

/**
 * Get ISO week number
 */
function getWeekNumber(date: Date): number {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil((d.getTime() - yearStart.getTime()) / 86400000 / 7);
}

export default generateWellnessReport;
