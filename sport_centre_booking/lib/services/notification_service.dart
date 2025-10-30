import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/notification_preferences.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of user's notifications (real-time)
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  /// Get unread count (real-time)
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final docs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in docs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  /// Save user preferences
  Future<void> savePreferences(
      String userId, NotificationPreferences prefs) async {
    try {
      print('🔧 NotificationService: Saving preferences for user $userId');
      print('   Method: ${prefs.method}');
      print('   Hours: ${prefs.reminderHoursBefore}');
      
      // Use set with merge to create the field if it doesn't exist
      await _firestore.collection('users').doc(userId).set({
        'notificationPreferences': prefs.toJson(),
      }, SetOptions(merge: true));
      
      print('✅ NotificationService: Preferences saved successfully');
      
      // Verify the save by reading it back
      final doc = await _firestore.collection('users').doc(userId).get();
      final savedData = doc.data()?['notificationPreferences'];
      print('🔍 Verification: Saved data = $savedData');
    } catch (e) {
      print('❌ NotificationService: Error saving preferences: $e');
      rethrow;
    }
  }

  /// Get user preferences
  Future<NotificationPreferences> getPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data()?['notificationPreferences'];
    return data != null
        ? NotificationPreferences.fromJson(data)
        : NotificationPreferences.defaults;
  }
}
