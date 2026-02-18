import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type enum
enum MessageType {
  text,
  voice,
  audio_file,
}

/// Voice/text message model
class Message {
  final String id;
  final String userId;
  final String conversationId;
  final MessageType type;
  final String content; // Text content or transcription
  final String? audioUrl; // URL to audio file if voice message
  final String? originalAudioPath; // Local path before upload
  final double? confidence; // Transcription confidence for voice messages
  final DateTime createdAt;
  final String? senderRole; // "user" or "assistant"
  final Map<String, dynamic> metadata;

  Message({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.type,
    required this.content,
    this.audioUrl,
    this.originalAudioPath,
    this.confidence,
    required this.createdAt,
    this.senderRole,
    this.metadata = const {},
  });

  /// Creates a copy with specified fields replaced
  Message copyWith({
    String? id,
    String? userId,
    String? conversationId,
    MessageType? type,
    String? content,
    String? audioUrl,
    String? originalAudioPath,
    double? confidence,
    DateTime? createdAt,
    String? senderRole,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
      content: content ?? this.content,
      audioUrl: audioUrl ?? this.audioUrl,
      originalAudioPath: originalAudioPath ?? this.originalAudioPath,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      senderRole: senderRole ?? this.senderRole,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'conversationId': conversationId,
      'type': type.toString().split('.').last,
      'content': content,
      'audioUrl': audioUrl,
      'originalAudioPath': originalAudioPath,
      'confidence': confidence,
      'createdAt': Timestamp.fromDate(createdAt),
      'senderRole': senderRole,
      'metadata': metadata,
    };
  }

  /// Creates from JSON (Firestore)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      type: _parseMessageType(json['type']),
      content: json['content'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      originalAudioPath: json['originalAudioPath'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderRole: json['senderRole'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Parses message type from string
  static MessageType _parseMessageType(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'voice':
          return MessageType.voice;
        case 'audio_file':
          return MessageType.audio_file;
        case 'text':
        default:
          return MessageType.text;
      }
    }
    return MessageType.text;
  }

  /// Checks if message is from user
  bool get isFromUser => senderRole == 'user';

  /// Checks if message is from assistant
  bool get isFromAssistant => senderRole == 'assistant';

  /// Checks if message has audio
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  /// Gets content preview (truncated)
  String get preview {
    const maxLength = 100;
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }

  /// Gets type label in Portuguese
  String get typeLabel {
    switch (type) {
      case MessageType.text:
        return 'Texto';
      case MessageType.voice:
        return 'Voz';
      case MessageType.audio_file:
        return 'Ficheiro de Áudio';
    }
  }

  /// Checks if transcription is high confidence
  bool get isHighConfidence => confidence != null && confidence! >= 0.85;

  @override
  String toString() {
    return 'Message(id: $id, type: ${type.toString()}, content length: ${content.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
