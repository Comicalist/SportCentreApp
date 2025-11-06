/// Notification delivery methods for user communications
enum NotificationMethod {
  email,  // Email notifications to user's registered address
  inApp;  // Push notifications within the mobile app

  String toJson() => name;
  static NotificationMethod fromJson(String json) =>
      NotificationMethod.values.firstWhere((e) => e.name == json);
}

/// User customizable notification settings for booking reminders
/// 
/// Controls how and when users receive notifications about their bookings,
/// including activity reminders, cancellations, and schedule changes.
/// Common reminder intervals: 1, 2, 4, 12, 24 hours before activity.
class NotificationPreferences {
  NotificationPreferences({
    required this.method,
    required this.reminderHoursBefore,
  });

  /// Create preferences from Firestore data with fallback defaults
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      method: NotificationMethod.fromJson(json['method'] ?? 'inApp'),
      reminderHoursBefore: json['reminderHoursBefore'] ?? 2,
    );
  }

  // Notification configuration
  final NotificationMethod method; // How to deliver notifications
  final int reminderHoursBefore; // When to send booking reminders

  /// Safe default settings for new users (in-app, 2 hours before)
  static NotificationPreferences get defaults => NotificationPreferences(
    method: NotificationMethod.inApp,
    reminderHoursBefore: 2,
  );

  /// Convert to Firestore format for storage
  Map<String, dynamic> toJson() {
    return {
      'method': method.toJson(),
      'reminderHoursBefore': reminderHoursBefore,
    };
  }
}
