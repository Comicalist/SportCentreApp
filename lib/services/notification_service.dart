import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/notification_preferences.dart';

/// Real-time notification system for booking updates and activity reminders
/// Handles user notification preferences, delivery methods, and read status tracking
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Real-time notification feed for user dashboard and notification center
  /// Provides chronological ordering with pagination for performance
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Pagination to prevent excessive data loading
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AppNotification.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Live unread count for badge display and user attention management
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark individual notification as read for user interaction tracking
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Bulk read operation for "mark all as read" functionality
  /// Uses batch operations for atomic updates and performance
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final docs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in docs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Remove individual notification from user's notification center
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  /// Persist user notification preferences for delivery method and timing
  /// Supports email and in-app notification configuration
  Future<void> savePreferences(
    String userId,
    NotificationPreferences prefs,
  ) async {
    try {
      /// Use merge operation to preserve other user data fields
      await _firestore.collection('users').doc(userId).set({
        'notificationPreferences': prefs.toJson(),
      }, SetOptions(merge: true));

    } catch (e) {
      rethrow;
    }
  }

  /// Retrieve user notification preferences with fallback to system defaults
  Future<NotificationPreferences> getPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data()?['notificationPreferences'];
    return data != null
        ? NotificationPreferences.fromJson(data)
        : NotificationPreferences.defaults;
  }

  /// Complete notification history cleanup for user account management
  /// Useful for privacy compliance and account deletion workflows
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      /// Batch deletion for atomic operation and performance optimization
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
