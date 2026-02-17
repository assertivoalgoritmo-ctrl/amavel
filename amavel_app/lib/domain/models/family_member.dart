import 'package:cloud_firestore/cloud_firestore.dart';

/// Family member model
class FamilyMember {
  final String id;
  final String userId;
  final String name;
  final String relationship; // e.g., "daughter", "son", "spouse", "friend"
  final String? phoneNumber;
  final String? email;
  final String? notes;
  final bool notificationEnabled;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    this.phoneNumber,
    this.email,
    this.notes,
    this.notificationEnabled = true,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  /// Creates a copy with specified fields replaced
  FamilyMember copyWith({
    String? id,
    String? userId,
    String? name,
    String? relationship,
    String? phoneNumber,
    String? email,
    String? notes,
    bool? notificationEnabled,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      notificationEnabled:
          notificationEnabled ?? this.notificationEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  /// Converts to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
      'email': email,
      'notes': notes,
      'notificationEnabled': notificationEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }

  /// Creates from JSON (Firestore)
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt:
          (json['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Gets the display name with relationship
  String get displayNameWithRelationship => '$name ($relationship)';

  /// Checks if member has contact information
  bool get hasContactInfo => phoneNumber != null || email != null;

  /// Validates the family member
  bool get isValid => name.isNotEmpty && relationship.isNotEmpty;

  /// Gets Portuguese relationship label
  String get relationshipLabel {
    switch (relationship.toLowerCase()) {
      case 'daughter':
        return 'Filha';
      case 'son':
        return 'Filho';
      case 'spouse':
        return 'Cônjuge';
      case 'friend':
        return 'Amigo/a';
      case 'sibling':
        return 'Irmão/ã';
      case 'grandchild':
        return 'Neto/a';
      case 'parent':
        return 'Pai/Mãe';
      case 'caregiver':
        return 'Cuidador/a';
      default:
        return relationship;
    }
  }

  @override
  String toString() {
    return 'FamilyMember(id: $id, name: $name, relationship: $relationship)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
