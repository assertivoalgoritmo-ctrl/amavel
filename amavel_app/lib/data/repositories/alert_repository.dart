import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amavel_app/domain/models/alert.dart';
import 'package:amavel_app/data/datasources/firestore_datasource.dart';

/// Repository for alert Firestore CRUD operations
class AlertRepository {
  final FirestoreDataSource _firestore;

  AlertRepository({FirestoreDataSource? firestore})
      : _firestore = firestore ?? FirestoreDataSource();

  /// Creates a new alert
  Future<String> createAlert({
    required String userId,
    required AlertSeverity severity,
    required String title,
    required String description,
    required String detectedPatterns,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final docRef = _firestore.alertsRef.doc();
      final alert = Alert(
        id: docRef.id,
        userId: userId,
        severity: severity,
        title: title,
        description: description,
        detectedPatterns: detectedPatterns,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await docRef.set(alert.toJson());
      return docRef.id;
    } catch (e) {
      print('Erro ao criar alerta: $e');
      rethrow;
    }
  }

  /// Gets an alert by ID
  Future<Alert?> getAlert(String alertId) async {
    try {
      final doc = await _firestore.alertsRef.doc(alertId).get();
      if (doc.exists) {
        return Alert.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar alerta: $e');
      return null;
    }
  }

  /// Gets all alerts for a user
  Future<List<Alert>> getUserAlerts(String userId) async {
    try {
      final snapshot = await _firestore.alertsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Alert.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar alertas do utilizador: $e');
      return [];
    }
  }

  /// Gets pending alerts for a user (not acknowledged)
  Future<List<Alert>> getPendingAlerts(String userId) async {
    try {
      final snapshot = await _firestore.alertsRef
          .where('userId', isEqualTo: userId)
          .where('acknowledgedAt', isNull: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Alert.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar alertas pendentes: $e');
      return [];
    }
  }

  /// Gets critical alerts for a user
  Future<List<Alert>> getCriticalAlerts(String userId) async {
    try {
      final snapshot = await _firestore.alertsRef
          .where('userId', isEqualTo: userId)
          .where('severity', isEqualTo: 'critical')
          .where('isResolved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Alert.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar alertas críticos: $e');
      return [];
    }
  }

  /// Acknowledges an alert
  Future<void> acknowledgeAlert(
    String alertId,
    String acknowledgedBy,
  ) async {
    try {
      await _firestore.alertsRef.doc(alertId).update({
        'acknowledgedAt': Timestamp.fromDate(DateTime.now()),
        'acknowledgedBy': acknowledgedBy,
      });
    } catch (e) {
      print('Erro ao reconhecer alerta: $e');
      rethrow;
    }
  }

  /// Resolves an alert
  Future<void> resolveAlert(
    String alertId,
    String resolutionNotes,
  ) async {
    try {
      await _firestore.alertsRef.doc(alertId).update({
        'isResolved': true,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
        'resolutionNotes': resolutionNotes,
      });
    } catch (e) {
      print('Erro ao resolver alerta: $e');
      rethrow;
    }
  }

  /// Updates alert metadata
  Future<void> updateAlert(Alert alert) async {
    try {
      await _firestore.alertsRef.doc(alert.id).update(alert.toJson());
    } catch (e) {
      print('Erro ao atualizar alerta: $e');
      rethrow;
    }
  }

  /// Gets alerts by severity
  Future<List<Alert>> getAlertsBySeverity(
    String userId,
    AlertSeverity severity,
  ) async {
    try {
      final severityStr = severity.toString().split('.').last;
      final snapshot = await _firestore.alertsRef
          .where('userId', isEqualTo: userId)
          .where('severity', isEqualTo: severityStr)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Alert.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar alertas por severidade: $e');
      return [];
    }
  }

  /// Gets unresolved alerts for a user
  Future<List<Alert>> getUnresolvedAlerts(String userId) async {
    try {
      final snapshot = await _firestore.alertsRef
          .where('userId', isEqualTo: userId)
          .where('isResolved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Alert.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar alertas não resolvidos: $e');
      return [];
    }
  }

  /// Deletes an alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore.alertsRef.doc(alertId).delete();
    } catch (e) {
      print('Erro ao eliminar alerta: $e');
      rethrow;
    }
  }

  /// Gets alert statistics for a user
  Future<Map<String, dynamic>> getAlertStats(String userId) async {
    try {
      final allAlerts = await getUserAlerts(userId);
      final critical = allAlerts
          .where((a) => a.severity == AlertSeverity.critical)
          .length;
      final high =
          allAlerts.where((a) => a.severity == AlertSeverity.high).length;
      final unresolved = allAlerts.where((a) => !a.isResolved).length;

      return {
        'totalAlerts': allAlerts.length,
        'criticalAlerts': critical,
        'highAlerts': high,
        'unresolvedAlerts': unresolved,
      };
    } catch (e) {
      print('Erro ao recuperar estatísticas de alertas: $e');
      return {};
    }
  }

  /// Streams alerts for a user
  Stream<List<Alert>> streamUserAlerts(String userId) {
    return _firestore.alertsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Alert.fromJson(doc.data()))
            .toList());
  }

  /// Streams critical alerts for a user
  Stream<List<Alert>> streamCriticalAlerts(String userId) {
    return _firestore.alertsRef
        .where('userId', isEqualTo: userId)
        .where('severity', isEqualTo: 'critical')
        .where('isResolved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Alert.fromJson(doc.data()))
            .toList());
  }
}
