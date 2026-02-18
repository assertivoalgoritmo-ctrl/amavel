import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, voice }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String content;
  final String? audioUrl;
  final String? transcript;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final Duration? audioLength;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.content,
    this.audioUrl,
    this.transcript,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.audioLength,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      recipientId: data['recipientId'] ?? '',
      content: data['content'] ?? '',
      audioUrl: data['audioUrl'],
      transcript: data['transcript'],
      type: _parseMessageType(data['type']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      audioLength: data['audioLength'] != null
          ? Duration(milliseconds: data['audioLength'] as int)
          : null,
    );
  }

  static MessageType _parseMessageType(String? type) {
    return type == 'voice' ? MessageType.voice : MessageType.text;
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'content': content,
      'audioUrl': audioUrl,
      'transcript': transcript,
      'type': type == MessageType.voice ? 'voice' : 'text',
      'timestamp': timestamp,
      'isRead': isRead,
      'audioLength': audioLength?.inMilliseconds,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? content,
    String? audioUrl,
    String? transcript,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    Duration? audioLength,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      audioUrl: audioUrl ?? this.audioUrl,
      transcript: transcript ?? this.transcript,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      audioLength: audioLength ?? this.audioLength,
    );
  }
}
