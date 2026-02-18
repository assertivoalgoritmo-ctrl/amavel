import 'package:cloud_firestore/cloud_firestore.dart';

/// Alert severity enum
enum AlertSeverity {
  critical,
  high,
  medium,
  low,
}

/// Distress alert model
class Alert {
  final String id;
  final String userId;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String detectedPatterns; // Comma-separated patterns detected
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final Map<String, dynamic> metadata;

  Alert({
    required this.id,
    required this.userId,
    required this.severity,
    required this.title,
    required this.description,
    required this.detectedPatterns,
    required this.createdAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.isResolved = false,
    this.resolvedAt,
    this.resolutionNotes,
    this.metadata = const {},
  });

  /// Creates a copy with specified fields replaced
  Alert copyWith({
    String? id,
    String? userId,
    AlertSeverity? severity,
    String? title,
    String? description,
    String? detectedPatterns,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    bool? isResolved,
    DateTime? resolvedAt,
    String? resolutionNotes,
    Map<String, dynamic>? metadata,
  }) {
    return Alert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      detectedPatterns: detectedPatterns ?? this.detectedPatterns,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'severity': severity.toString().split('.').last,
      'title': title,
      'description': description,
      'detectedPatterns': detectedPatterns,
      'createdAt': Timestamp.fromDate(createdAt),
      'acknowledgedAt':
          acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'acknowledgedBy': acknowledgedBy,
      'isResolved': isResolved,
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolutionNotes': resolutionNotes,
      'metadata': metadata,
    };
  }

  /// Creates from JSON (Firestore)
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      severity: _parseSeverity(json['severity']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      detectedPatterns: json['detectedPatterns'] as String? ?? '',
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acknowledgedAt: (json['acknowledgedAt'] as Timestamp?)?.toDate(),
      acknowledgedBy: json['acknowledgedBy'] as String?,
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedAt: (json['resolvedAt'] as Timestamp?)?.toDate(),
      resolutionNotes: json['resolutionNotes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Parses severity from string
  static AlertSeverity _parseSeverity(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'critical':
          return AlertSeverity.critical;
        case 'high':
          return AlertSeverity.high;
        case 'medium':
          return AlertSeverity.medium;
        case 'low':
        default:
          return AlertSeverity.low;
      }
    }
    return AlertSeverity.low;
  }

  /// Gets severity label in Portuguese
  String get severityLabel {
    switch (severity) {
      case AlertSeverity.critical:
        return 'Crítico';
      case AlertSeverity.high:
        return 'Elevado';
      case AlertSeverity.medium:
        return 'Moderado';
      case AlertSeverity.low:
        return 'Baixo';
    }
  }

  /// Gets numeric severity for sorting (higher = more severe)
  int get severityScore {
    switch (severity) {
      case AlertSeverity.critical:
        return 4;
      case AlertSeverity.high:
        return 3;
      case AlertSeverity.medium:
        return 2;
      case AlertSeverity.low:
        return 1;
    }
  }

  /// Checks if alert is pending (not acknowledged)
  bool get isPending => acknowledgedAt == null;

  /// Checks if alert is acknowledged but not resolved
  bool get isAcknowledgedPending =>
      acknowledgedAt != null && !isResolved;

  /// Gets time since creation
  Duration get timeSinceCreation => DateTime.now().difference(createdAt);

  /// Gets a list of detected patterns
  List<String> get patterns =>
      detectedPatterns.split(',').map((p) => p.trim()).toList();

  /// Formats time since creation
  String get formattedTimeSince {
    final duration = timeSinceCreation;
    if (duration.inHours == 0) {
      return '${duration.inMinutes}m atrás';
    } else if (duration.inDays == 0) {
      return '${duration.inHours}h atrás';
    } else {
      return '${duration.inDays}d atrás';
    }
  }

  @override
  String toString() {
    return 'Alert(id: $id, severity: ${severity.toString()}, title: $title)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alert && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
