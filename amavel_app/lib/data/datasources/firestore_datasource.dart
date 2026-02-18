import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central Firestore access with collection references and common operations
class FirestoreDataSource {
  static final FirestoreDataSource _instance =
      FirestoreDataSource._internal();

  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;

  factory FirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    if (firestore != null) {
      _instance._firestore = firestore;
    } else {
      _instance._firestore ??= FirebaseFirestore.instance;
    }

    if (auth != null) {
      _instance._auth = auth;
    } else {
      _instance._auth ??= FirebaseAuth.instance;
    }

    return _instance;
  }

  FirestoreDataSource._internal();

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// User profiles collection reference
  CollectionReference<Map<String, dynamic>> get userProfileRef =>
      _firestore.collection('user_profiles');

  /// Memory facts collection reference
  CollectionReference<Map<String, dynamic>> get memoryFactsRef =>
      _firestore.collection('memory_facts');

  /// Conversations collection reference
  CollectionReference<Map<String, dynamic>> get conversationsRef =>
      _firestore.collection('conversations');

  /// Conversation turns collection reference
  CollectionReference<Map<String, dynamic>> get conversationTurnsRef =>
      _firestore.collection('conversation_turns');

  /// Messages collection reference
  CollectionReference<Map<String, dynamic>> get messagesRef =>
      _firestore.collection('messages');

  /// Alerts collection reference
  CollectionReference<Map<String, dynamic>> get alertsRef =>
      _firestore.collection('alerts');

  /// Family members collection reference
  CollectionReference<Map<String, dynamic>> get familyMembersRef =>
      _firestore.collection('family_members');

  /// Sets Firestore instance (for testing)
  void setFirestore(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  /// Sets Firebase Auth instance (for testing)
  void setAuth(FirebaseAuth auth) {
    _auth = auth;
  }

  /// Common operation: batch write
  WriteBatch batch() {
    return _firestore.batch();
  }

  /// Common operation: transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) transactionHandler,
  ) {
    return _firestore.runTransaction(transactionHandler);
  }

  /// Deletes a document from a collection
  Future<void> deleteDocument(String path) async {
    try {
      await _firestore.doc(path).delete();
    } catch (e) {
      print('Erro ao eliminar documento: $e');
      rethrow;
    }
  }

  /// Gets a document from a collection
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String path,
  ) async {
    try {
      return await _firestore.doc(path).get();
    } catch (e) {
      print('Erro ao recuperar documento: $e');
      rethrow;
    }
  }

  /// Sets a document in a collection
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _firestore.doc(path).set(data, SetOptions(merge: merge));
    } catch (e) {
      print('Erro ao definir documento: $e');
      rethrow;
    }
  }

  /// Updates a document in a collection
  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.doc(path).update(data);
    } catch (e) {
      print('Erro ao atualizar documento: $e');
      rethrow;
    }
  }

  /// Checks if a document exists
  Future<bool> documentExists(String path) async {
    try {
      final doc = await _firestore.doc(path).get();
      return doc.exists;
    } catch (e) {
      print('Erro ao verificar existência do documento: $e');
      return false;
    }
  }

  /// Clears all data for a user (GDPR right to be forgotten)
  /// WARNING: This deletes all user data and is irreversible
  Future<void> deleteAllUserData(String userId) async {
    try {
      final batch = _firestore.batch();

      // Delete user profile
      batch.delete(userProfileRef.doc(userId));

      // Delete all memory facts
      final memoryFacts = await memoryFactsRef
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in memoryFacts.docs) {
        batch.delete(doc.reference);
      }

      // Delete all conversations
      final conversations = await conversationsRef
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in conversations.docs) {
        batch.delete(doc.reference);
      }

      // Delete all conversation turns
      final turns = await conversationTurnsRef
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in turns.docs) {
        batch.delete(doc.reference);
      }

      // Delete all messages
      final messages = await messagesRef
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete all alerts
      final alerts = await alertsRef
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in alerts.docs) {
        batch.delete(doc.reference);
      }

      // Delete all family members
      final familyMembers = await familyMembersRef
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in familyMembers.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Todos os dados do utilizador foram eliminados: $userId');
    } catch (e) {
      print('Erro ao eliminar todos os dados do utilizador: $e');
      rethrow;
    }
  }

  /// Gets database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final userProfiles = await userProfileRef.count().get();
      final memoryFacts = await memoryFactsRef.count().get();
      final conversations = await conversationsRef.count().get();
      final turns = await conversationTurnsRef.count().get();
      final messages = await messagesRef.count().get();
      final alerts = await alertsRef.count().get();
      final familyMembers = await familyMembersRef.count().get();

      return {
        'userProfiles': userProfiles.count,
        'memoryFacts': memoryFacts.count,
        'conversations': conversations.count,
        'conversationTurns': turns.count,
        'messages': messages.count,
        'alerts': alerts.count,
        'familyMembers': familyMembers.count,
      };
    } catch (e) {
      print('Erro ao recuperar estatísticas do banco de dados: $e');
      return {};
    }
  }
}
