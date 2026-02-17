import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation metadata model
class Conversation {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;
  final List<String> turnIds;
  final int turnCount;
  final String topic; // Free-form topic description
  final bool isActive;

  Conversation({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.lastUpdatedAt,
    this.turnIds = const [],
    this.turnCount = 0,
    this.topic = '',
    this.isActive = true,
  });

  /// Creates a copy with specified fields replaced
  Conversation copyWith({
    String? id,
    String? userId,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    List<String>? turnIds,
    int? turnCount,
    String? topic,
    bool? isActive,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      turnIds: turnIds ?? this.turnIds,
      turnCount: turnCount ?? this.turnCount,
      topic: topic ?? this.topic,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Converts to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startedAt': Timestamp.fromDate(startedAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'turnIds': turnIds,
      'turnCount': turnCount,
      'topic': topic,
      'isActive': isActive,
    };
  }

  /// Creates from JSON (Firestore)
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      startedAt: (json['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt:
          (json['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      turnIds: List<String>.from(json['turnIds'] as List? ?? []),
      turnCount: json['turnCount'] as int? ?? 0,
      topic: json['topic'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Gets the duration of the conversation
  Duration get duration => lastUpdatedAt.difference(startedAt);

  /// Gets duration as formatted string
  String get formattedDuration {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  String toString() {
    return 'Conversation(id: $id, userId: $userId, turns: $turnCount, topic: $topic)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
