import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model
class UserProfile {
  final String id;
  final String? displayName;
  final DateTime? dateOfBirth;
  final String language; // default: "pt-PT"
  final VoicePreferences voicePreferences;
  final List<String> familyMemberIds;
  final String assistantName; // default: "AMAVEL"
  final bool onboardingCompleted;
  final DateTime? gdprConsentAt;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  UserProfile({
    required this.id,
    this.displayName,
    this.dateOfBirth,
    this.language = 'pt-PT',
    required this.voicePreferences,
    this.familyMemberIds = const [],
    this.assistantName = 'AMAVEL',
    this.onboardingCompleted = false,
    this.gdprConsentAt,
    required this.createdAt,
    required this.lastActiveAt,
  });

  /// Creates a copy of this profile with specified fields replaced
  UserProfile copyWith({
    String? id,
    String? displayName,
    DateTime? dateOfBirth,
    String? language,
    VoicePreferences? voicePreferences,
    List<String>? familyMemberIds,
    String? assistantName,
    bool? onboardingCompleted,
    DateTime? gdprConsentAt,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      language: language ?? this.language,
      voicePreferences: voicePreferences ?? this.voicePreferences,
      familyMemberIds: familyMemberIds ?? this.familyMemberIds,
      assistantName: assistantName ?? this.assistantName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      gdprConsentAt: gdprConsentAt ?? this.gdprConsentAt,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// Converts to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'language': language,
      'voicePreferences': voicePreferences.toJson(),
      'familyMemberIds': familyMemberIds,
      'assistantName': assistantName,
      'onboardingCompleted': onboardingCompleted,
      'gdprConsentAt': gdprConsentAt != null ? Timestamp.fromDate(gdprConsentAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }

  /// Creates from JSON (Firestore)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String?,
      dateOfBirth: (json['dateOfBirth'] as Timestamp?)?.toDate(),
      language: json['language'] as String? ?? 'pt-PT',
      voicePreferences: json['voicePreferences'] != null
          ? VoicePreferences.fromJson(
              json['voicePreferences'] as Map<String, dynamic>)
          : VoicePreferences(),
      familyMemberIds: List<String>.from(json['familyMemberIds'] as List? ?? []),
      assistantName: json['assistantName'] as String? ?? 'AMAVEL',
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      gdprConsentAt: (json['gdprConsentAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt:
          (json['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, displayName: $displayName, language: $language, assistantName: $assistantName)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Voice preferences model
class VoicePreferences {
  final double speed; // 0.5 - 2.0
  final double volume; // 0.0 - 1.0
  final String voiceGender; // "female" or "male"

  VoicePreferences({
    this.speed = 1.0,
    this.volume = 1.0,
    this.voiceGender = 'female',
  });

  /// Validates speed is within range
  bool get isSpeedValid => speed >= 0.5 && speed <= 2.0;

  /// Validates volume is within range
  bool get isVolumeValid => volume >= 0.0 && volume <= 1.0;

  /// Creates a copy with specified fields replaced
  VoicePreferences copyWith({
    double? speed,
    double? volume,
    String? voiceGender,
  }) {
    return VoicePreferences(
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      voiceGender: voiceGender ?? this.voiceGender,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'speed': speed,
      'volume': volume,
      'voiceGender': voiceGender,
    };
  }

  /// Creates from JSON
  factory VoicePreferences.fromJson(Map<String, dynamic> json) {
    return VoicePreferences(
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      voiceGender: json['voiceGender'] as String? ?? 'female',
    );
  }

  @override
  String toString() {
    return 'VoicePreferences(speed: $speed, volume: $volume, voiceGender: $voiceGender)';
  }
}
