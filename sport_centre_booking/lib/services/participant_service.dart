import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/participant.dart';
import '../models/booking.dart';

/// Service for managing event participants in admin panel
/// Handles CRUD operations with real-time Firestore synchronization
class ParticipantService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _bookingsCollection = 'bookings';
  static const String _usersCollection = 'users';
  static const String _activitiesCollection = 'activities';

  /// Get all participants with real-time updates
  static Stream<List<Participant>> getAllParticipants() {
    return _firestore
        .collection(_bookingsCollection)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Participant> participants = [];

      for (var doc in snapshot.docs) {
        try {
          final bookingData = doc.data();
          final userId = bookingData['userId'] as String?;

          if (userId == null) continue;

          // Fetch user data
          final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
          final userData = userDoc.exists 
              ? Map<String, dynamic>.from(userDoc.data() ?? {}) 
              : <String, dynamic>{};

          participants.add(Participant.fromFirestore(doc, userData));
        } catch (e) {
          print('Error processing participant ${doc.id}: $e');
        }
      }

      return participants;
    });
  }

  /// Get participants for a specific activity
  static Stream<List<Participant>> getParticipantsByActivity(String activityId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('activityId', isEqualTo: activityId)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Participant> participants = [];

      for (var doc in snapshot.docs) {
        try {
          final bookingData = doc.data();
          final userId = bookingData['userId'] as String?;

          if (userId == null) continue;

          final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
          final userData = userDoc.exists 
              ? Map<String, dynamic>.from(userDoc.data() ?? {}) 
              : <String, dynamic>{};

          participants.add(Participant.fromFirestore(doc, userData));
        } catch (e) {
          print('Error processing participant ${doc.id}: $e');
        }
      }

      return participants;
    });
  }

  /// Get participants filtered by status
  static Stream<List<Participant>> getParticipantsByStatus(BookingStatus status) {
    return _firestore
        .collection(_bookingsCollection)
        .where('status', isEqualTo: status.value)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Participant> participants = [];

      for (var doc in snapshot.docs) {
        try {
          final bookingData = doc.data();
          final userId = bookingData['userId'] as String?;

          if (userId == null) continue;

          final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
          final userData = userDoc.exists 
              ? Map<String, dynamic>.from(userDoc.data() ?? {}) 
              : <String, dynamic>{};

          participants.add(Participant.fromFirestore(doc, userData));
        } catch (e) {
          print('Error processing participant ${doc.id}: $e');
        }
      }

      return participants;
    });
  }

  /// Get a single participant by booking ID
  static Future<Participant?> getParticipant(String bookingId) async {
    try {
      final bookingDoc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();

      if (!bookingDoc.exists) {
        print('Booking not found: $bookingId');
        return null;
      }

      final bookingData = bookingDoc.data()!;
      final userId = bookingData['userId'] as String?;

      if (userId == null) {
        print('User ID not found in booking: $bookingId');
        return null;
      }

      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      final userData = userDoc.exists 
          ? Map<String, dynamic>.from(userDoc.data() ?? {}) 
          : <String, dynamic>{};

      return Participant.fromFirestore(bookingDoc, userData);
    } catch (e) {
      print('Error getting participant $bookingId: $e');
      return null;
    }
  }

  /// Update participant booking details
  /// Returns true if successful, false otherwise
  static Future<bool> updateParticipant(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print('Updating participant $bookingId with: $updates');

      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection(_bookingsCollection).doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking not found');
        }

        final bookingData = bookingDoc.data()!;
        final oldStatus = bookingData['status'] as String?;
        final newStatus = updates['status'] as String?;
        final activityId = bookingData['activityId'] as String;

        // Update the booking
        transaction.update(bookingRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // If status changed, update activity capacity
        if (oldStatus != null && newStatus != null && oldStatus != newStatus) {
          await _updateActivityCapacity(
            transaction,
            activityId,
            bookingId,
            oldStatus,
            newStatus,
            bookingData['participantCount'] as int? ?? 1,
          );
        }
      });

      print('Participant $bookingId updated successfully');
      return true;
    } catch (e) {
      print('Error updating participant $bookingId: $e');
      return false;
    }
  }

  /// Update participant status
  static Future<bool> updateParticipantStatus(
    String bookingId,
    BookingStatus newStatus, {
    String? reason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        updates['notes'] = reason;
      }

      if (newStatus == BookingStatus.cancelled) {
        updates['cancelledAt'] = FieldValue.serverTimestamp();
        updates['cancellationReason'] = reason ?? 'Cancelled by admin';
      }

      return await updateParticipant(bookingId, updates);
    } catch (e) {
      print('Error updating participant status: $e');
      return false;
    }
  }

  /// Remove participant (delete booking)
  /// This also updates activity capacity and user bookings
  static Future<bool> removeParticipant(String bookingId) async {
    try {
      print('Removing participant $bookingId');

      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore.collection(_bookingsCollection).doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking not found');
        }

        final bookingData = bookingDoc.data()!;
        final activityId = bookingData['activityId'] as String;
        final userId = bookingData['userId'] as String;
        final participantCount = bookingData['participantCount'] as int? ?? 1;

        // Delete the booking
        transaction.delete(bookingRef);

        // Update activity booked count
        final activityRef = _firestore.collection(_activitiesCollection).doc(activityId);
        transaction.update(activityRef, {
          'bookedCount': FieldValue.increment(-participantCount),
          'spotsLeft': FieldValue.increment(participantCount),
        });

        // Remove from user's bookings
        final userRef = _firestore.collection(_usersCollection).doc(userId);
        transaction.update(userRef, {
          'upcomingBookings': FieldValue.arrayRemove([bookingId]),
        });
      });

      print('Participant $bookingId removed successfully');
      return true;
    } catch (e) {
      print('Error removing participant $bookingId: $e');
      return false;
    }
  }

  /// Search participants by name, email, or confirmation number
  static Stream<List<Participant>> searchParticipants(String query) {
    final lowerQuery = query.toLowerCase();

    return getAllParticipants().map((participants) {
      return participants.where((participant) {
        return participant.userName.toLowerCase().contains(lowerQuery) ||
            participant.userEmail.toLowerCase().contains(lowerQuery) ||
            participant.confirmationNumber.toLowerCase().contains(lowerQuery) ||
            participant.activityTitle.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  /// Get participant statistics
  static Future<Map<String, dynamic>> getParticipantStats() async {
    try {
      final snapshot = await _firestore.collection(_bookingsCollection).get();

      int total = snapshot.docs.length;
      int confirmed = 0;
      int pending = 0;
      int cancelled = 0;
      int completed = 0;
      double totalRevenue = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final amount = (data['amountPaid'] as num?)?.toDouble() ?? 0;

        switch (status) {
          case 'confirmed':
            confirmed++;
            totalRevenue += amount;
            break;
          case 'pending':
            pending++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'completed':
            completed++;
            totalRevenue += amount;
            break;
        }
      }

      return {
        'total': total,
        'confirmed': confirmed,
        'pending': pending,
        'cancelled': cancelled,
        'completed': completed,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      print('Error getting participant stats: $e');
      return {
        'total': 0,
        'confirmed': 0,
        'pending': 0,
        'cancelled': 0,
        'completed': 0,
        'totalRevenue': 0.0,
      };
    }
  }

  /// Helper method to update activity capacity when status changes
  static Future<void> _updateActivityCapacity(
    Transaction transaction,
    String activityId,
    String bookingId,
    String oldStatus,
    String newStatus,
    int participantCount,
  ) async {
    final activityRef = _firestore.collection(_activitiesCollection).doc(activityId);

    // Determine if we need to adjust capacity
    final wasActive = oldStatus == 'confirmed' || oldStatus == 'pending';
    final isActive = newStatus == 'confirmed' || newStatus == 'pending';

    if (wasActive && !isActive) {
      // Freeing up spots (cancellation/completion)
      transaction.update(activityRef, {
        'bookedCount': FieldValue.increment(-participantCount),
        'spotsLeft': FieldValue.increment(participantCount),
      });
    } else if (!wasActive && isActive) {
      // Taking up spots (reactivation)
      transaction.update(activityRef, {
        'bookedCount': FieldValue.increment(participantCount),
        'spotsLeft': FieldValue.increment(-participantCount),
      });
    }
  }

  /// Bulk update participants status
  static Future<Map<String, bool>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus newStatus, {
    String? reason,
  }) async {
    Map<String, bool> results = {};

    for (var bookingId in bookingIds) {
      final success = await updateParticipantStatus(bookingId, newStatus, reason: reason);
      results[bookingId] = success;
    }

    return results;
  }

  /// Export participants data (for CSV or reports)
  static Future<List<Map<String, dynamic>>> exportParticipants({
    String? activityId,
    BookingStatus? status,
  }) async {
    try {
      Query query = _firestore.collection(_bookingsCollection);

      if (activityId != null) {
        query = query.where('activityId', isEqualTo: activityId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> exportData = [];

      for (var doc in snapshot.docs) {
        final bookingData = doc.data() as Map<String, dynamic>;
        final userId = bookingData['userId'] as String?;

        Map<String, dynamic> userData = {};
        if (userId != null) {
          final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
          userData = userDoc.exists ? userDoc.data() ?? {} : {};
        }

        exportData.add({
          'bookingId': doc.id,
          'userName': userData['name'] ?? 'Unknown',
          'userEmail': userData['email'] ?? '',
          'phoneNumber': userData['phoneNumber'] ?? '',
          'activityTitle': bookingData['activityTitle'] ?? '',
          'activityDate': bookingData['activityDate']?.toString() ?? '',
          'activityTime': bookingData['activityTime'] ?? '',
          'bookingDate': bookingData['bookingDate']?.toString() ?? '',
          'status': bookingData['status'] ?? '',
          'participantCount': bookingData['participantCount'] ?? 1,
          'amountPaid': bookingData['amountPaid'] ?? 0,
          'isMemberBooking': bookingData['isMemberBooking'] ?? false,
          'confirmationNumber': bookingData['confirmationNumber'] ?? '',
          'notes': bookingData['notes'] ?? '',
        });
      }

      return exportData;
    } catch (e) {
      print('Error exporting participants: $e');
      return [];
    }
  }
}
