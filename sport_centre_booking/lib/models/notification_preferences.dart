/// How to receive notifications
enum NotificationMethod {
  email,
  inApp;

  String toJson() => name;
  static NotificationMethod fromJson(String json) => 
    NotificationMethod.values.firstWhere((e) => e.name == json);
}

/// User's notification preferences
class NotificationPreferences {
  final NotificationMethod method;
  final int reminderHoursBefore; // 1, 2, 4, 12, 24

  NotificationPreferences({
    required this.method,
    required this.reminderHoursBefore,
  });

  /// Default preferences
  static NotificationPreferences get defaults => NotificationPreferences(
    method: NotificationMethod.inApp,
    reminderHoursBefore: 2,
  );

  /// From Firestore
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      method: NotificationMethod.fromJson(json['method'] ?? 'inApp'),
      reminderHoursBefore: json['reminderHoursBefore'] ?? 2,
    );
  }

  /// To Firestore
  Map<String, dynamic> toJson() {
    return {
      'method': method.toJson(),
      'reminderHoursBefore': reminderHoursBefore,
    };
  }
}
