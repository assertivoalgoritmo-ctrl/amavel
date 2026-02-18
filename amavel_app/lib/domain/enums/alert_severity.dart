/// Severity levels for distress/safety alerts.
enum AlertSeverity {
  /// Minor concern, included in weekly wellness report
  low,

  /// Moderate concern, noted for family review
  medium,

  /// Significant concern, FCM push within 1 hour
  high,

  /// Immediate danger, instant FCM push to all family
  critical,
}

extension AlertSeverityExtension on AlertSeverity {
  String get portugueseLabel {
    switch (this) {
      case AlertSeverity.low:
        return 'Baixo';
      case AlertSeverity.medium:
        return 'Médio';
      case AlertSeverity.high:
        return 'Alto';
      case AlertSeverity.critical:
        return 'Crítico';
    }
  }

  bool get requiresImmediateNotification =>
      this == AlertSeverity.critical || this == AlertSeverity.high;
}
