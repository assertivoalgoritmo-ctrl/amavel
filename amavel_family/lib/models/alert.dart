import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertSeverity { low, medium, high, critical }

class Alert {
  final String id;
  final String seniorId;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool acknowledged;
  final bool resolved;
  final String? resolvedNotes;
  final DateTime? resolvedAt;
  final String? acknowledgedBy;
  final List<String> notifiedFamilyMembers;

  Alert({
    required this.id,
    required this.seniorId,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.acknowledged = false,
    this.resolved = false,
    this.resolvedNotes,
    this.resolvedAt,
    this.acknowledgedBy,
    List<String>? notifiedFamilyMembers,
  }) : notifiedFamilyMembers = notifiedFamilyMembers ?? [];

  factory Alert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Alert(
      id: doc.id,
      seniorId: data['seniorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      severity: _parseSeverity(data['severity']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acknowledged: data['acknowledged'] ?? false,
      resolved: data['resolved'] ?? false,
      resolvedNotes: data['resolvedNotes'],
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      acknowledgedBy: data['acknowledgedBy'],
      notifiedFamilyMembers: List<String>.from(data['notifiedFamilyMembers'] ?? []),
    );
  }

  static AlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'medium':
        return AlertSeverity.medium;
      case 'high':
        return AlertSeverity.high;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.low;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'seniorId': seniorId,
      'title': title,
      'description': description,
      'severity': severity.toString().split('.').last,
      'timestamp': timestamp,
      'acknowledged': acknowledged,
      'resolved': resolved,
      'resolvedNotes': resolvedNotes,
      'resolvedAt': resolvedAt,
      'acknowledgedBy': acknowledgedBy,
      'notifiedFamilyMembers': notifiedFamilyMembers,
    };
  }

  Alert copyWith({
    String? id,
    String? seniorId,
    String? title,
    String? description,
    AlertSeverity? severity,
    DateTime? timestamp,
    bool? acknowledged,
    bool? resolved,
    String? resolvedNotes,
    DateTime? resolvedAt,
    String? acknowledgedBy,
    List<String>? notifiedFamilyMembers,
  }) {
    return Alert(
      id: id ?? this.id,
      seniorId: seniorId ?? this.seniorId,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      resolved: resolved ?? this.resolved,
      resolvedNotes: resolvedNotes ?? this.resolvedNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      notifiedFamilyMembers: notifiedFamilyMembers ?? this.notifiedFamilyMembers,
    );
  }
}
