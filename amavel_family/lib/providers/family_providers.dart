import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../services/alert_service.dart';
import '../services/fcm_service.dart';
import '../models/senior_profile.dart';
import '../models/message.dart';
import '../models/alert.dart';

// Services
final authServiceProvider = Provider((ref) => AuthService());
final messagingServiceProvider = Provider((ref) => MessagingService());
final alertServiceProvider = Provider((ref) => AlertService());

// Auth State
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// Senior Profile
final linkedSeniorIdProvider = FutureProvider<String?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();

  return doc.data()?['linkedSeniorId'] as String?;
});

final seniorProfileProvider = FutureProvider<SeniorProfile?>((ref) async {
  final seniorId = await ref.watch(linkedSeniorIdProvider.future);
  if (seniorId == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(seniorId)
      .get();

  if (!doc.exists) return null;

  return SeniorProfile.fromFirestore(doc);
});

final seniorProfileStreamProvider = StreamProvider<SeniorProfile?>((ref) async* {
  final seniorId = await ref.watch(linkedSeniorIdProvider.future);
  if (seniorId == null) {
    yield null;
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('users')
      .doc(seniorId)
      .snapshots()
      .map((doc) => doc.exists ? SeniorProfile.fromFirestore(doc) : null);
});

// Messages
final messagesProvider = StreamProvider<List<Message>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider);
  final seniorId = await ref.watch(linkedSeniorIdProvider.future);

  if (currentUser == null || seniorId == null) {
    yield [];
    return;
  }

  final messagingService = ref.watch(messagingServiceProvider);
  yield* messagingService.getMessages(seniorId, currentUser.uid);
});

final messageCountProvider = FutureProvider<int>((ref) async {
  final messages = await ref.watch(messagesProvider.future);
  return messages.length;
});

// Alerts
final alertsProvider = StreamProvider<List<Alert>>((ref) async* {
  final seniorId = await ref.watch(linkedSeniorIdProvider.future);
  if (seniorId == null) {
    yield [];
    return;
  }

  final alertService = ref.watch(alertServiceProvider);
  yield* alertService.getAlerts(seniorId);
});

final unresolvedAlertsProvider = StreamProvider<List<Alert>>((ref) async* {
  final seniorId = await ref.watch(linkedSeniorIdProvider.future);
  if (seniorId == null) {
    yield [];
    return;
  }

  final alertService = ref.watch(alertServiceProvider);
  yield* alertService.getUnresolvedAlerts(seniorId);
});

final criticalAlertsProvider = StreamProvider<List<Alert>>((ref) async* {
  final seniorId = await ref.watch(linkedSeniorIdProvider.future);
  if (seniorId == null) {
    yield [];
    return;
  }

  final alertService = ref.watch(alertServiceProvider);
  yield* alertService.getAlertsBySeverity(seniorId, 'critical');
});

final alertSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final seniorId = await ref.watch(linkedSeniorIdProvider.future);
  if (seniorId == null) return {'total_unresolved': 0, 'critical': 0};

  final alertService = ref.watch(alertServiceProvider);
  return alertService.getAlertSummary(seniorId);
});

final unresolvedAlertCountProvider = FutureProvider<int>((ref) async {
  final seniorId = await ref.watch(linkedSeniorIdProvider.future);
  if (seniorId == null) return 0;

  final alertService = ref.watch(alertServiceProvider);
  return alertService.getUnresolvedAlertCount(seniorId);
});

// Actions
final sendVoiceMessageProvider = FutureProvider.family
    .autoDispose<void, (String, String, String)>((ref, args) async {
  // Implementation handled in the page
});

final sendTextMessageProvider = FutureProvider.family
    .autoDispose<void, (String, String)>((ref, args) async {
  // Implementation handled in the page
});

final acknowledgeAlertProvider =
    FutureProvider.family.autoDispose<void, (String, String)>((ref, args) async {
  final seniorId = args.$1;
  final alertId = args.$2;
  final alertService = ref.watch(alertServiceProvider);
  await alertService.acknowledgeAlert(seniorId, alertId);
  ref.invalidate(alertsProvider);
  ref.invalidate(unresolvedAlertsProvider);
});

final resolveAlertProvider = FutureProvider.family
    .autoDispose<void, (String, String, String?)>((ref, args) async {
  final seniorId = args.$1;
  final alertId = args.$2;
  final notes = args.$3;
  final alertService = ref.watch(alertServiceProvider);
  await alertService.resolveAlert(
    seniorId: seniorId,
    alertId: alertId,
    notes: notes,
  );
  ref.invalidate(alertsProvider);
  ref.invalidate(unresolvedAlertsProvider);
  ref.invalidate(alertSummaryProvider);
});

// Preferences
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, Map<String, bool>>(
  (ref) => NotificationSettingsNotifier(),
);

class NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  NotificationSettingsNotifier()
      : super({
          'critical': true,
          'high': true,
          'medium': true,
          'low': true,
        });

  void toggleNotification(String severity) {
    state = {...state, severity: !state[severity]!};
  }

  void setAll(bool enabled) {
    state = {
      'critical': enabled,
      'high': enabled,
      'medium': enabled,
      'low': enabled,
    };
  }
}
