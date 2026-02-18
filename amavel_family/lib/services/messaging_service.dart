import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/message.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> sendVoiceMessage({
    required String senderId,
    required String senderName,
    required String recipientId,
    required File audioFile,
    String? transcript,
    Duration? audioLength,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final timestamp = DateTime.now();

      final audioUrl = await _uploadAudioFile(
        senderId,
        recipientId,
        messageId,
        audioFile,
      );

      final message = Message(
        id: messageId,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        content: 'Mensagem de voz',
        audioUrl: audioUrl,
        transcript: transcript,
        type: MessageType.voice,
        timestamp: timestamp,
        isRead: false,
        audioLength: audioLength,
      );

      await _firestore
          .collection('conversations')
          .doc('${senderId}_$recipientId')
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      await _firestore
          .collection('conversations')
          .doc('${senderId}_$recipientId')
          .update({
        'lastMessage': 'Mensagem de voz',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
      });
    } catch (e) {
      throw 'Erro ao enviar mensagem de voz: $e';
    }
  }

  Future<void> sendTextMessage({
    required String senderId,
    required String senderName,
    required String recipientId,
    required String text,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final timestamp = DateTime.now();

      final message = Message(
        id: messageId,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        content: text,
        type: MessageType.text,
        timestamp: timestamp,
        isRead: false,
      );

      await _firestore
          .collection('conversations')
          .doc('${senderId}_$recipientId')
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      await _firestore
          .collection('conversations')
          .doc('${senderId}_$recipientId')
          .update({
        'lastMessage': text,
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
      }).catchError((_) {
        return _firestore
            .collection('conversations')
            .doc('${senderId}_$recipientId')
            .set({
          'lastMessage': text,
          'lastMessageTime': timestamp,
          'lastMessageSenderId': senderId,
          'participants': [senderId, recipientId],
          'createdAt': timestamp,
        });
      });
    } catch (e) {
      throw 'Erro ao enviar mensagem: $e';
    }
  }

  Stream<List<Message>> getMessages(String seniorId, String familyMemberId) {
    return _firestore
        .collection('conversations')
        .doc('${familyMemberId}_$seniorId')
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  Future<String> _uploadAudioFile(
    String senderId,
    String recipientId,
    String messageId,
    File audioFile,
  ) async {
    try {
      final ref = _storage.ref().child(
            'audio_messages/$senderId/$recipientId/$messageId.m4a',
          );

      await ref.putFile(audioFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Erro ao fazer upload de áudio: $e';
    }
  }

  Future<void> markMessagesAsRead(
    String senderId,
    String recipientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc('${recipientId}_$senderId')
          .collection('messages')
          .where('recipientId', isEqualTo: recipientId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      throw 'Erro ao marcar mensagens como lidas: $e';
    }
  }

  Future<void> deleteMessage(
    String senderId,
    String recipientId,
    String messageId,
  ) async {
    try {
      await _firestore
          .collection('conversations')
          .doc('${senderId}_$recipientId')
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw 'Erro ao deletar mensagem: $e';
    }
  }
}
