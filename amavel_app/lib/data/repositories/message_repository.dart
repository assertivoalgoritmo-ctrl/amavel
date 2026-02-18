import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amavel_app/domain/models/message.dart';
import 'package:amavel_app/data/datasources/firestore_datasource.dart';

/// Repository for message Firestore CRUD operations
class MessageRepository {
  final FirestoreDataSource _firestore;

  MessageRepository({FirestoreDataSource? firestore})
      : _firestore = firestore ?? FirestoreDataSource();

  /// Creates a new message
  Future<String> createMessage({
    required String userId,
    required String conversationId,
    required MessageType type,
    required String content,
    String? audioUrl,
    String? originalAudioPath,
    double? confidence,
    String? senderRole,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final docRef = _firestore.messagesRef.doc();
      final message = Message(
        id: docRef.id,
        userId: userId,
        conversationId: conversationId,
        type: type,
        content: content,
        audioUrl: audioUrl,
        originalAudioPath: originalAudioPath,
        confidence: confidence,
        createdAt: DateTime.now(),
        senderRole: senderRole,
        metadata: metadata ?? {},
      );

      await docRef.set(message.toJson());
      return docRef.id;
    } catch (e) {
      print('Erro ao criar mensagem: $e');
      rethrow;
    }
  }

  /// Gets a message by ID
  Future<Message?> getMessage(String messageId) async {
    try {
      final doc = await _firestore.messagesRef.doc(messageId).get();
      if (doc.exists) {
        return Message.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar mensagem: $e');
      return null;
    }
  }

  /// Gets all messages for a conversation
  Future<List<Message>> getConversationMessages(String conversationId) async {
    try {
      final snapshot = await _firestore.messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar mensagens da conversa: $e');
      return [];
    }
  }

  /// Gets all user messages for a conversation
  Future<List<Message>> getUserMessagesInConversation(
    String conversationId,
  ) async {
    try {
      final snapshot = await _firestore.messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .where('senderRole', isEqualTo: 'user')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar mensagens do utilizador: $e');
      return [];
    }
  }

  /// Gets all assistant messages for a conversation
  Future<List<Message>> getAssistantMessagesInConversation(
    String conversationId,
  ) async {
    try {
      final snapshot = await _firestore.messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .where('senderRole', isEqualTo: 'assistant')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar mensagens do assistente: $e');
      return [];
    }
  }

  /// Gets voice messages for a conversation
  Future<List<Message>> getVoiceMessages(String conversationId) async {
    try {
      final snapshot = await _firestore.messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .where('type', isEqualTo: 'voice')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar mensagens de voz: $e');
      return [];
    }
  }

  /// Gets the last message in a conversation
  Future<Message?> getLastMessage(String conversationId) async {
    try {
      final snapshot = await _firestore.messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Message.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar última mensagem: $e');
      return null;
    }
  }

  /// Updates a message
  Future<void> updateMessage(Message message) async {
    try {
      await _firestore.messagesRef.doc(message.id).update(message.toJson());
    } catch (e) {
      print('Erro ao atualizar mensagem: $e');
      rethrow;
    }
  }

  /// Deletes a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.messagesRef.doc(messageId).delete();
    } catch (e) {
      print('Erro ao eliminar mensagem: $e');
      rethrow;
    }
  }

  /// Gets all voice messages for a user
  Future<List<Message>> getUserVoiceMessages(String userId) async {
    try {
      final snapshot = await _firestore.messagesRef
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'voice')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar mensagens de voz do utilizador: $e');
      return [];
    }
  }

  /// Gets message statistics for a conversation
  Future<Map<String, dynamic>> getConversationMessageStats(
    String conversationId,
  ) async {
    try {
      final messages = await getConversationMessages(conversationId);
      final userMessages = messages.where((m) => m.isFromUser).length;
      final assistantMessages =
          messages.where((m) => m.isFromAssistant).length;
      final voiceMessages =
          messages.where((m) => m.type == MessageType.voice).length;

      return {
        'totalMessages': messages.length,
        'userMessages': userMessages,
        'assistantMessages': assistantMessages,
        'voiceMessages': voiceMessages,
      };
    } catch (e) {
      print('Erro ao recuperar estatísticas de mensagens: $e');
      return {};
    }
  }

  /// Gets high-confidence transcriptions
  Future<List<Message>> getHighConfidenceMessages(
    String conversationId,
  ) async {
    try {
      final messages = await getConversationMessages(conversationId);
      return messages
          .where((m) => m.type == MessageType.voice && m.isHighConfidence)
          .toList();
    } catch (e) {
      print('Erro ao recuperar mensagens de alta confiança: $e');
      return [];
    }
  }

  /// Streams conversation messages
  Stream<List<Message>> streamConversationMessages(String conversationId) {
    return _firestore.messagesRef
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromJson(doc.data()))
            .toList());
  }

  /// Streams only user messages
  Stream<List<Message>> streamUserMessages(String conversationId) {
    return _firestore.messagesRef
        .where('conversationId', isEqualTo: conversationId)
        .where('senderRole', isEqualTo: 'user')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromJson(doc.data()))
            .toList());
  }
}
