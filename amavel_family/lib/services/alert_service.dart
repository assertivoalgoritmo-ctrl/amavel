import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alert.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Alert>> getAlerts(String seniorId) {
    return _firestore
        .collection('users')
        .doc(seniorId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Alert.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Alert>> getUnresolvedAlerts(String seniorId) {
    return _firestore
        .collection('users')
        .doc(seniorId)
        .collection('alerts')
        .where('resolved', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Alert.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Alert>> getAlertsBySeverity(String seniorId, String severity) {
    return _firestore
        .collection('users')
        .doc(seniorId)
        .collection('alerts')
        .where('severity', isEqualTo: severity)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Alert.fromFirestore(doc)).toList();
    });
  }

  Future<void> acknowledgeAlert(String seniorId, String alertId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Usuário não autenticado';

      await _firestore
          .collection('users')
          .doc(seniorId)
          .collection('alerts')
          .doc(alertId)
          .update({
        'acknowledged': true,
        'acknowledgedBy': currentUser.uid,
        'acknowledgedAt': DateTime.now(),
      });
    } catch (e) {
      throw 'Erro ao confirmar alerta: $e';
    }
  }

  Future<void> resolveAlert({
    required String seniorId,
    required String alertId,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Usuário não autenticado';

      await _firestore
          .collection('users')
          .doc(seniorId)
          .collection('alerts')
          .doc(alertId)
          .update({
        'resolved': true,
        'resolvedAt': DateTime.now(),
        'resolvedNotes': notes ?? '',
        'acknowledgedBy': currentUser.uid,
      });
    } catch (e) {
      throw 'Erro ao resolver alerta: $e';
    }
  }

  Future<void> createAlert({
    required String seniorId,
    required String title,
    required String description,
    required String severity,
    List<String>? notifiedFamilyMembers,
  }) async {
    try {
      final alertRef = _firestore
          .collection('users')
          .doc(seniorId)
          .collection('alerts')
          .doc();

      await alertRef.set({
        'title': title,
        'description': description,
        'severity': severity,
        'timestamp': DateTime.now(),
        'acknowledged': false,
        'resolved': false,
        'notifiedFamilyMembers': notifiedFamilyMembers ?? [],
      });
    } catch (e) {
      throw 'Erro ao criar alerta: $e';
    }
  }

  Future<Alert?> getAlertById(String seniorId, String alertId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(seniorId)
          .collection('alerts')
          .doc(alertId)
          .get();

      if (doc.exists) {
        return Alert.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Erro ao buscar alerta: $e';
    }
  }

  Future<int> getUnresolvedAlertCount(String seniorId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(seniorId)
          .collection('alerts')
          .where('resolved', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw 'Erro ao contar alertas: $e';
    }
  }

  Future<Map<String, int>> getAlertSummary(String seniorId) async {
    try {
      final unresolvedSnapshot = await _firestore
          .collection('users')
          .doc(seniorId)
          .collection('alerts')
          .where('resolved', isEqualTo: false)
          .count()
          .get();

      final criticalSnapshot = await _firestore
          .collection('users')
          .doc(seniorId)
          .collection('alerts')
          .where('severity', isEqualTo: 'critical')
          .where('resolved', isEqualTo: false)
          .count()
          .get();

      return {
        'total_unresolved': unresolvedSnapshot.count ?? 0,
        'critical': criticalSnapshot.count ?? 0,
      };
    } catch (e) {
      throw 'Erro ao buscar resumo de alertas: $e';
    }
  }
}
