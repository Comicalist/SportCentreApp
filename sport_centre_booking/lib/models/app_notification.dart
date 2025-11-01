import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of notifications
enum NotificationType {
  bookingReminder,      // Reminder X hours before booking
  bookingCancellation;  // Booking was cancelled

  String toJson() => name;
  static NotificationType fromJson(String json) => 
    NotificationType.values.firstWhere((e) => e.name == json);
}

/// Notification model
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? bookingId;
  final String? activityName;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.bookingId,
    this.activityName,
  });

  /// From Firestore
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.fromJson(json['type'] ?? 'bookingReminder'),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      bookingId: json['bookingId'],
      activityName: json['activityName'],
    );
  }

  /// To Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.toJson(),
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'bookingId': bookingId,
      'activityName': activityName,
    };
  }
}
