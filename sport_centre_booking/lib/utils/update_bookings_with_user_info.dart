import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time script to update existing bookings with user info
/// Run this once to populate userName and userEmail fields in existing bookings
class UpdateBookingsWithUserInfo {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update all bookings that are missing userName and userEmail fields
  static Future<void> updateAllBookings() async {
    try {
      // Get all bookings
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      
      for (var bookingDoc in bookingsSnapshot.docs) {
        try {
          final bookingData = bookingDoc.data();
          
          // Skip if already has user info
          if (bookingData['userName'] != null && bookingData['userEmail'] != null) {
            continue;
          }
          
          final userId = bookingData['userId'] as String?;
          
          if (userId == null) {
            continue;
          }
          
          // Fetch user document
          final userDoc = await _firestore.collection('users').doc(userId).get();
          
          if (!userDoc.exists) {
            continue;
          }
          
          final userData = userDoc.data();
          final userName = userData?['displayName'] ?? 'Unknown User';
          final userEmail = userData?['email'] ?? '';
          
          // Update booking with user info
          await bookingDoc.reference.update({
            'userName': userName,
            'userEmail': userEmail,
          });
          
        } catch (e) {
          // Skip bookings with errors
          continue;
        }
      }
      
    } catch (e) {
      rethrow;
    }
  }
}
