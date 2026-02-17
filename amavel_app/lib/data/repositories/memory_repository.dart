import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amavel_app/domain/models/memory_fact.dart';
import 'package:amavel_app/data/datasources/firestore_datasource.dart';

/// Repository for memory fact Firestore CRUD operations
class MemoryRepository {
  final FirestoreDataSource _firestore;

  MemoryRepository({FirestoreDataSource? firestore})
      : _firestore = firestore ?? FirestoreDataSource();

  /// Stores a new fact or updates existing one (deduplication)
  Future<void> storeFact({
    required String category,
    required String key,
    required String value,
    required double extractionConfidence,
  }) async {
    try {
      final userId = _firestore.currentUserId;
      if (userId == null) {
        throw Exception('Utilizador não autenticado');
      }

      // Check for existing fact with same category+key
      final existingQuery = await _firestore.memoryFactsRef
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('key', isEqualTo: key)
          .limit(1)
          .get();

      final now = DateTime.now();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing fact
        final docId = existingQuery.docs.first.id;
        await _firestore.memoryFactsRef.doc(docId).update({
          'value': value,
          'extractionConfidence': extractionConfidence,
          'lastUpdatedAt': Timestamp.fromDate(now),
          'isActive': true,
        });
      } else {
        // Create new fact
        final newFact = MemoryFact(
          id: _firestore.memoryFactsRef.doc().id,
          userId: userId,
          category: category,
          key: key,
          value: value,
          extractionConfidence: extractionConfidence,
          extractedAt: now,
          lastUpdatedAt: now,
          isActive: true,
        );

        await _firestore.memoryFactsRef.doc(newFact.id).set(newFact.toJson());
      }
    } catch (e) {
      print('Erro ao armazenar facto de memória: $e');
      rethrow;
    }
  }

  /// Gets facts for the current user
  Future<List<MemoryFact>> getFactsForUser({String? category}) async {
    try {
      final userId = _firestore.currentUserId;
      if (userId == null) {
        return [];
      }

      Query query = _firestore.memoryFactsRef
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MemoryFact.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar factos de memória: $e');
      return [];
    }
  }

  /// Gets a specific fact by ID
  Future<MemoryFact?> getFactById(String factId) async {
    try {
      final doc = await _firestore.memoryFactsRef.doc(factId).get();
      if (doc.exists) {
        return MemoryFact.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar facto de memória: $e');
      return null;
    }
  }

  /// Updates an existing fact
  Future<void> updateFact(MemoryFact fact) async {
    try {
      await _firestore.memoryFactsRef.doc(fact.id).update({
        'category': fact.category,
        'key': fact.key,
        'value': fact.value,
        'extractionConfidence': fact.extractionConfidence,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
        'isActive': fact.isActive,
      });
    } catch (e) {
      print('Erro ao atualizar facto de memória: $e');
      rethrow;
    }
  }

  /// Deactivates a fact (soft delete)
  Future<void> deactivateFact(String factId) async {
    try {
      await _firestore.memoryFactsRef.doc(factId).update({
        'isActive': false,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Erro ao desativar facto de memória: $e');
      rethrow;
    }
  }

  /// Deletes a fact permanently
  Future<void> deleteFact(String factId) async {
    try {
      await _firestore.memoryFactsRef.doc(factId).delete();
    } catch (e) {
      print('Erro ao eliminar facto de memória: $e');
      rethrow;
    }
  }

  /// Gets facts by category
  Future<List<MemoryFact>> getFactsByCategory(String category) async {
    try {
      final userId = _firestore.currentUserId;
      if (userId == null) {
        return [];
      }

      final snapshot = await _firestore.memoryFactsRef
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => MemoryFact.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar factos por categoria: $e');
      return [];
    }
  }

  /// Searches facts by key or value
  Future<List<MemoryFact>> searchFacts(String query) async {
    try {
      final userId = _firestore.currentUserId;
      if (userId == null) {
        return [];
      }

      final snapshot = await _firestore.memoryFactsRef
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final lowercaseQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => MemoryFact.fromJson(doc.data()))
          .where((fact) =>
              fact.key.toLowerCase().contains(lowercaseQuery) ||
              fact.value.toLowerCase().contains(lowercaseQuery))
          .toList();
    } catch (e) {
      print('Erro ao pesquisar factos de memória: $e');
      return [];
    }
  }

  /// Gets facts sorted by last updated (most recent first)
  Future<List<MemoryFact>> getRecentFacts({int limit = 10}) async {
    try {
      final userId = _firestore.currentUserId;
      if (userId == null) {
        return [];
      }

      final snapshot = await _firestore.memoryFactsRef
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastUpdatedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MemoryFact.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar factos recentes: $e');
      return [];
    }
  }

  /// Gets high-confidence facts (confidence >= 0.8)
  Future<List<MemoryFact>> getHighConfidenceFacts() async {
    try {
      final userId = _firestore.currentUserId;
      if (userId == null) {
        return [];
      }

      final snapshot = await _firestore.memoryFactsRef
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .where('extractionConfidence', isGreaterThanOrEqualTo: 0.8)
          .get();

      return snapshot.docs
          .map((doc) => MemoryFact.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar factos de alta confiança: $e');
      return [];
    }
  }

  /// Streams facts for a user
  Stream<List<MemoryFact>> streamUserFacts() {
    final userId = _firestore.currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore.memoryFactsRef
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemoryFact.fromJson(doc.data()))
            .toList());
  }
}
