import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../models/booking.dart';
import '../models/participant.dart';

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
          final participants = <Participant>[];

          for (final doc in snapshot.docs) {
            try {
              final bookingData = doc.data();
              final userId = bookingData['userId'] as String?;

              if (userId == null) continue;

              // Fetch user data
              final userDoc = await _firestore
                  .collection(_usersCollection)
                  .doc(userId)
                  .get();
              final userData = userDoc.exists
                  ? Map<String, dynamic>.from(userDoc.data() ?? {})
                  : <String, dynamic>{};

              participants.add(Participant.fromFirestore(doc, userData));
            } on FirebaseException catch (e) {
              logger.w('Firebase error processing participant ${doc.id}', 
                error: e, stackTrace: StackTrace.current);
            } catch (e, stackTrace) {
              logger.e('Unexpected error processing participant ${doc.id}', 
                error: e, stackTrace: stackTrace);
            }
          }

          return participants;
        });
  }

  /// Get participants for a specific activity
  static Stream<List<Participant>> getParticipantsByActivity(
    String activityId,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('activityId', isEqualTo: activityId)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final participants = <Participant>[];

          for (final doc in snapshot.docs) {
            try {
              final bookingData = doc.data();
              final userId = bookingData['userId'] as String?;

              if (userId == null) continue;

              final userDoc = await _firestore
                  .collection(_usersCollection)
                  .doc(userId)
                  .get();
              final userData = userDoc.exists
                  ? Map<String, dynamic>.from(userDoc.data() ?? {})
                  : <String, dynamic>{};

              participants.add(Participant.fromFirestore(doc, userData));
            } on FirebaseException catch (e) {
              logger.w('Firebase error processing participant ${doc.id}', 
                error: e, stackTrace: StackTrace.current);
            } catch (e, stackTrace) {
              logger.e('Unexpected error processing participant ${doc.id}', 
                error: e, stackTrace: stackTrace);
            }
          }

          return participants;
        });
  }

  /// Get participants filtered by status
  static Stream<List<Participant>> getParticipantsByStatus(
    BookingStatus status,
  ) {
    return _firestore
        .collection(_bookingsCollection)
        .where('status', isEqualTo: status.value)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final participants = <Participant>[];

          for (final doc in snapshot.docs) {
            try {
              final bookingData = doc.data();
              final userId = bookingData['userId'] as String?;

              if (userId == null) continue;

              final userDoc = await _firestore
                  .collection(_usersCollection)
                  .doc(userId)
                  .get();
              final userData = userDoc.exists
                  ? Map<String, dynamic>.from(userDoc.data() ?? {})
                  : <String, dynamic>{};

              participants.add(Participant.fromFirestore(doc, userData));
            } on FirebaseException catch (e) {
              logger.w('Firebase error processing participant ${doc.id}', 
                error: e, stackTrace: StackTrace.current);
            } catch (e, stackTrace) {
              logger.e('Unexpected error processing participant ${doc.id}', 
                error: e, stackTrace: stackTrace);
            }
          }

          return participants;
        });
  }

  /// Get a single participant by booking ID
  /// 
  /// Returns null if booking not found or user data is invalid.
  /// Throws [FirebaseException] for Firebase-related errors.
  static Future<Participant?> getParticipant(String bookingId) async {
    try {
      final bookingDoc = await _firestore
          .collection(_bookingsCollection)
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        logger.w('Booking not found: $bookingId');
        return null;
      }

      final bookingData = bookingDoc.data()!;
      final userId = bookingData['userId'] as String?;

      if (userId == null) {
        logger.w('User ID not found in booking: $bookingId');
        return null;
      }

      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      final userData = userDoc.exists
          ? Map<String, dynamic>.from(userDoc.data() ?? {})
          : <String, dynamic>{};

      return Participant.fromFirestore(bookingDoc, userData);
    } on FirebaseException catch (e) {
      logger.e('Firebase error getting participant $bookingId', 
        error: e, stackTrace: StackTrace.current);
      rethrow;
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting participant $bookingId', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update participant booking details
  /// 
  /// Returns true if successful, false otherwise.
  /// Throws exceptions for critical errors that should be handled by caller.
  static Future<bool> updateParticipant(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      logger.d('Updating participant $bookingId with: $updates');

      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore
            .collection(_bookingsCollection)
            .doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw StateError('Booking not found: $bookingId');
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

      logger.i('Participant $bookingId updated successfully');
      return true;
    } on FirebaseException catch (e) {
      logger.e('Firebase error updating participant $bookingId', 
        error: e, stackTrace: StackTrace.current);
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error updating participant $bookingId', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Update participant status
  /// 
  /// [reason] is optional and will be added to notes field.
  /// For cancellations, automatically sets cancellation timestamp and reason.
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
    } catch (e, stackTrace) {
      logger.e('Error updating participant status', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Remove participant (delete booking)
  /// 
  /// This also updates activity capacity and user bookings.
  /// Returns true if successful, false otherwise.
  static Future<bool> removeParticipant(String bookingId) async {
    try {
      logger.i('Removing participant $bookingId');

      await _firestore.runTransaction((transaction) async {
        final bookingRef = _firestore
            .collection(_bookingsCollection)
            .doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw StateError('Booking not found: $bookingId');
        }

        final bookingData = bookingDoc.data()!;
        final activityId = bookingData['activityId'] as String;
        final userId = bookingData['userId'] as String;
        final participantCount = bookingData['participantCount'] as int? ?? 1;

        // Delete the booking
        transaction.delete(bookingRef);

        // Update activity booked count
        final activityRef = _firestore
            .collection(_activitiesCollection)
            .doc(activityId);
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

      logger.i('Participant $bookingId removed successfully');
      return true;
    } on FirebaseException catch (e) {
      logger.e('Firebase error removing participant $bookingId', 
        error: e, stackTrace: StackTrace.current);
      return false;
    } catch (e, stackTrace) {
      logger.e('Unexpected error removing participant $bookingId', 
        error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Search participants by name, email, or confirmation number
  /// 
  /// Performs client-side filtering on the participant stream.
  /// For better performance with large datasets, consider server-side search.
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
  /// 
  /// Returns a map with counts for each status and total revenue.
  /// In case of error, returns zeroed stats to prevent UI crashes.
  static Future<Map<String, dynamic>> getParticipantStats() async {
    try {
      final snapshot = await _firestore.collection(_bookingsCollection).get();

      final total = snapshot.docs.length;
      var confirmed = 0;
      var pending = 0;
      var cancelled = 0;
      var completed = 0;
      double totalRevenue = 0;

      for (final doc in snapshot.docs) {
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
    } on FirebaseException catch (e) {
      logger.e('Firebase error getting participant stats', 
        error: e, stackTrace: StackTrace.current);
      return _getEmptyStats();
    } catch (e, stackTrace) {
      logger.e('Unexpected error getting participant stats', 
        error: e, stackTrace: stackTrace);
      return _getEmptyStats();
    }
  }

  /// Returns empty stats map to prevent UI crashes
  static Map<String, dynamic> _getEmptyStats() {
    return {
      'total': 0,
      'confirmed': 0,
      'pending': 0,
      'cancelled': 0,
      'completed': 0,
      'totalRevenue': 0.0,
    };
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
    final activityRef = _firestore
        .collection(_activitiesCollection)
        .doc(activityId);

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
  /// 
  /// Returns a map of booking IDs to their update success status.
  /// Use this for batch operations to avoid multiple individual calls.
  static Future<Map<String, bool>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus newStatus, {
    String? reason,
  }) async {
    final results = <String, bool>{};

    for (final bookingId in bookingIds) {
      final success = await updateParticipantStatus(
        bookingId,
        newStatus,
        reason: reason,
      );
      results[bookingId] = success;
    }

    return results;
  }

  /// Export participants data (for CSV or reports)
  /// 
  /// [activityId] and [status] are optional filters.
  /// Returns list of maps suitable for CSV export or report generation.
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
      final exportData = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final bookingData = doc.data()! as Map<String, dynamic>;
        final userId = bookingData['userId'] as String?;

        var userData = <String, dynamic>{};
        if (userId != null) {
          final userDoc = await _firestore
              .collection(_usersCollection)
              .doc(userId)
              .get();
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

      logger.i('Exported ${exportData.length} participant records');
      return exportData;
    } on FirebaseException catch (e) {
      logger.e('Firebase error exporting participants', 
        error: e, stackTrace: StackTrace.current);
      return [];
    } catch (e, stackTrace) {
      logger.e('Unexpected error exporting participants', 
        error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
