import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amavel_app/domain/models/conversation.dart';
import 'package:amavel_app/domain/models/conversation_turn.dart';
import 'package:amavel_app/data/datasources/firestore_datasource.dart';

/// Repository for conversation Firestore CRUD operations
class ConversationRepository {
  final FirestoreDataSource _firestore;

  ConversationRepository({FirestoreDataSource? firestore})
      : _firestore = firestore ?? FirestoreDataSource();

  /// Creates a new conversation
  Future<String> createConversation({
    required String userId,
    String topic = '',
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _firestore.conversationsRef.doc();
      final conversation = Conversation(
        id: docRef.id,
        userId: userId,
        startedAt: now,
        lastUpdatedAt: now,
        topic: topic,
      );

      await docRef.set(conversation.toJson());
      return docRef.id;
    } catch (e) {
      print('Erro ao criar conversa: $e');
      rethrow;
    }
  }

  /// Gets a conversation by ID
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore.conversationsRef.doc(conversationId).get();
      if (doc.exists) {
        return Conversation.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar conversa: $e');
      return null;
    }
  }

  /// Gets all conversations for a user
  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      final snapshot = await _firestore.conversationsRef
          .where('userId', isEqualTo: userId)
          .orderBy('lastUpdatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Conversation.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar conversas do utilizador: $e');
      return [];
    }
  }

  /// Updates conversation metadata
  Future<void> updateConversation(Conversation conversation) async {
    try {
      await _firestore.conversationsRef.doc(conversation.id).update({
        'topic': conversation.topic,
        'turnCount': conversation.turnCount,
        'turnIds': conversation.turnIds,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
        'isActive': conversation.isActive,
      });
    } catch (e) {
      print('Erro ao atualizar conversa: $e');
      rethrow;
    }
  }

  /// Adds a turn to the conversation
  Future<void> addTurnToConversation(
    String conversationId,
    String turnId,
  ) async {
    try {
      await _firestore.conversationsRef.doc(conversationId).update({
        'turnIds': FieldValue.arrayUnion([turnId]),
        'turnCount': FieldValue.increment(1),
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Erro ao adicionar turno à conversa: $e');
      rethrow;
    }
  }

  /// Closes a conversation
  Future<void> closeConversation(String conversationId) async {
    try {
      await _firestore.conversationsRef.doc(conversationId).update({
        'isActive': false,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Erro ao fechar conversa: $e');
      rethrow;
    }
  }

  /// Creates a conversation turn
  Future<String> createConversationTurn({
    required String conversationId,
    required String userId,
    required int turnNumber,
    required String userInput,
    required String assistantResponse,
    List<String> functionsUsed = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final docRef = _firestore.conversationTurnsRef.doc();
      final turn = ConversationTurn(
        id: docRef.id,
        conversationId: conversationId,
        userId: userId,
        turnNumber: turnNumber,
        userInput: userInput,
        assistantResponse: assistantResponse,
        createdAt: DateTime.now(),
        functionsUsed: functionsUsed,
        metadata: metadata ?? {},
      );

      await docRef.set(turn.toJson());

      // Add turn to conversation
      await addTurnToConversation(conversationId, docRef.id);

      return docRef.id;
    } catch (e) {
      print('Erro ao criar turno de conversa: $e');
      rethrow;
    }
  }

  /// Gets a conversation turn by ID
  Future<ConversationTurn?> getConversationTurn(String turnId) async {
    try {
      final doc = await _firestore.conversationTurnsRef.doc(turnId).get();
      if (doc.exists) {
        return ConversationTurn.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar turno de conversa: $e');
      return null;
    }
  }

  /// Gets all turns for a conversation
  Future<List<ConversationTurn>> getConversationTurns(
    String conversationId,
  ) async {
    try {
      final snapshot = await _firestore.conversationTurnsRef
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('turnNumber', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ConversationTurn.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar turnos de conversa: $e');
      return [];
    }
  }

  /// Updates a conversation turn
  Future<void> updateConversationTurn(ConversationTurn turn) async {
    try {
      await _firestore.conversationTurnsRef.doc(turn.id).update(turn.toJson());
    } catch (e) {
      print('Erro ao atualizar turno de conversa: $e');
      rethrow;
    }
  }

  /// Gets the most recent conversation for a user
  Future<Conversation?> getLatestConversation(String userId) async {
    try {
      final snapshot = await _firestore.conversationsRef
          .where('userId', isEqualTo: userId)
          .orderBy('lastUpdatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Conversation.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar conversa recente: $e');
      return null;
    }
  }

  /// Gets conversation statistics for a user
  Future<Map<String, dynamic>> getConversationStats(String userId) async {
    try {
      final conversations = await getUserConversations(userId);
      final totalConversations = conversations.length;
      final totalTurns =
          conversations.fold<int>(0, (sum, c) => sum + c.turnCount);
      final averageTurnsPerConversation = totalConversations > 0
          ? totalTurns / totalConversations
          : 0.0;

      return {
        'totalConversations': totalConversations,
        'totalTurns': totalTurns,
        'averageTurnsPerConversation': averageTurnsPerConversation,
      };
    } catch (e) {
      print('Erro ao recuperar estatísticas de conversa: $e');
      return {};
    }
  }

  /// Streams conversations for a user
  Stream<List<Conversation>> streamUserConversations(String userId) {
    return _firestore.conversationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('lastUpdatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromJson(doc.data()))
            .toList());
  }
}
