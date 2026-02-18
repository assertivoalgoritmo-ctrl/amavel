import 'package:cloud_firestore/cloud_firestore.dart';

class SeniorProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final String? profileImageUrl;
  final DateTime? lastActiveTime;
  final bool isOnline;
  final String emergencyContact;

  SeniorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    this.profileImageUrl,
    this.lastActiveTime,
    this.isOnline = false,
    required this.emergencyContact,
  });

  factory SeniorProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SeniorProfile(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: data['profileImageUrl'],
      lastActiveTime: (data['lastActiveTime'] as Timestamp?)?.toDate(),
      isOnline: data['isOnline'] ?? false,
      emergencyContact: data['emergencyContact'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'profileImageUrl': profileImageUrl,
      'lastActiveTime': lastActiveTime,
      'isOnline': isOnline,
      'emergencyContact': emergencyContact,
    };
  }

  SeniorProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    DateTime? lastActiveTime,
    bool? isOnline,
    String? emergencyContact,
  }) {
    return SeniorProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      isOnline: isOnline ?? this.isOnline,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
