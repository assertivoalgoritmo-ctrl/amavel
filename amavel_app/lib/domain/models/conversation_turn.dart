import 'package:cloud_firestore/cloud_firestore.dart';

/// Single conversation turn model
class ConversationTurn {
  final String id;
  final String conversationId;
  final String userId;
  final int turnNumber;
  final String userInput;
  final String assistantResponse;
  final DateTime createdAt;
  final List<String> functionsUsed;
  final Map<String, dynamic> metadata;

  ConversationTurn({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.turnNumber,
    required this.userInput,
    required this.assistantResponse,
    required this.createdAt,
    this.functionsUsed = const [],
    this.metadata = const {},
  });

  /// Creates a copy with specified fields replaced
  ConversationTurn copyWith({
    String? id,
    String? conversationId,
    String? userId,
    int? turnNumber,
    String? userInput,
    String? assistantResponse,
    DateTime? createdAt,
    List<String>? functionsUsed,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationTurn(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      turnNumber: turnNumber ?? this.turnNumber,
      userInput: userInput ?? this.userInput,
      assistantResponse: assistantResponse ?? this.assistantResponse,
      createdAt: createdAt ?? this.createdAt,
      functionsUsed: functionsUsed ?? this.functionsUsed,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'userId': userId,
      'turnNumber': turnNumber,
      'userInput': userInput,
      'assistantResponse': assistantResponse,
      'createdAt': Timestamp.fromDate(createdAt),
      'functionsUsed': functionsUsed,
      'metadata': metadata,
    };
  }

  /// Creates from JSON (Firestore)
  factory ConversationTurn.fromJson(Map<String, dynamic> json) {
    return ConversationTurn(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      turnNumber: json['turnNumber'] as int? ?? 0,
      userInput: json['userInput'] as String? ?? '',
      assistantResponse: json['assistantResponse'] as String? ?? '',
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      functionsUsed:
          List<String>.from(json['functionsUsed'] as List? ?? []),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Gets the character count of user input
  int get userInputLength => userInput.length;

  /// Gets the character count of assistant response
  int get assistantResponseLength => assistantResponse.length;

  /// Checks if any functions were used in this turn
  bool get hasFunctionCalls => functionsUsed.isNotEmpty;

  @override
  String toString() {
    return 'ConversationTurn(id: $id, turn: $turnNumber, functions: ${functionsUsed.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationTurn &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
