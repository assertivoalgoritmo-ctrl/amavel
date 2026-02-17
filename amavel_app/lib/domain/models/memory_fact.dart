import 'package:cloud_firestore/cloud_firestore.dart';

/// Memory fact model for storing user information
class MemoryFact {
  final String id;
  final String userId;
  final String category; // family, health, preference, schedule, history
  final String key;
  final String value;
  final double extractionConfidence;
  final DateTime extractedAt;
  final DateTime lastUpdatedAt;
  final bool isActive;

  MemoryFact({
    required this.id,
    required this.userId,
    required this.category,
    required this.key,
    required this.value,
    required this.extractionConfidence,
    required this.extractedAt,
    required this.lastUpdatedAt,
    this.isActive = true,
  });

  /// Creates a copy with specified fields replaced
  MemoryFact copyWith({
    String? id,
    String? userId,
    String? category,
    String? key,
    String? value,
    double? extractionConfidence,
    DateTime? extractedAt,
    DateTime? lastUpdatedAt,
    bool? isActive,
  }) {
    return MemoryFact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      key: key ?? this.key,
      value: value ?? this.value,
      extractionConfidence:
          extractionConfidence ?? this.extractionConfidence,
      extractedAt: extractedAt ?? this.extractedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Converts to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'key': key,
      'value': value,
      'extractionConfidence': extractionConfidence,
      'extractedAt': Timestamp.fromDate(extractedAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'isActive': isActive,
    };
  }

  /// Creates from JSON (Firestore)
  factory MemoryFact.fromJson(Map<String, dynamic> json) {
    return MemoryFact(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      category: json['category'] as String? ?? 'history',
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      extractionConfidence:
          (json['extractionConfidence'] as num?)?.toDouble() ?? 0.0,
      extractedAt:
          (json['extractedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt:
          (json['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Validates the fact
  bool get isValid => key.isNotEmpty && value.isNotEmpty;

  /// Gets a human-readable category label in Portuguese
  String get categoryLabel {
    switch (category) {
      case 'family':
        return 'Família';
      case 'health':
        return 'Saúde';
      case 'preference':
        return 'Preferência';
      case 'schedule':
        return 'Rotina';
      case 'history':
        return 'História';
      default:
        return category;
    }
  }

  @override
  String toString() {
    return 'MemoryFact(id: $id, category: $category, key: $key, value: $value, confidence: ${(extractionConfidence * 100).toStringAsFixed(0)}%)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryFact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode;
}
