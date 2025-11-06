import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity.dart';
import '../models/booking.dart';
import '../models/voucher.dart';

/// Comprehensive booking management service for sport centre reservations
/// Handles real-time availability, voucher integration, points rewards, and transactional consistency
class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Real-time availability validation for booking interface
  /// Supports both general activity capacity and specific time slot allocation
  static Future<bool> checkAvailability(
    String activityId,
    String? timeSlotId,
  ) async {
    try {
      final activityDoc = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();

      if (!activityDoc.exists) return false;

      final activityData = activityDoc.data()!;

      /// General activity capacity validation for simple bookings
      if (timeSlotId == null) {
        final capacity = activityData['capacity'] ?? 0;
        final bookedCount = activityData['bookedCount'] ?? 0;
        return bookedCount < capacity;
      }

      /// Time slot specific availability for complex scheduling
      final timeSlots = activityData['timeSlots'] as List<dynamic>? ?? [];
      final timeSlot = timeSlots.firstWhere(
        (slot) => slot['id'] == timeSlotId,
        orElse: () => null,
      );

      if (timeSlot == null) return false;

      final capacity = timeSlot['capacity'] ?? 0;
      final bookedCount = timeSlot['bookedCount'] ?? 0;
      final isAvailable = timeSlot['isAvailable'] ?? true;

      return isAvailable && bookedCount < capacity;
    } catch (e) {
      return false;
    }
  }

  /// Create new booking with atomic transaction to prevent overbooking and ensure data consistency
  /// Integrates voucher validation, capacity management, and points calculation
  static Future<Booking?> createBooking({
    required String activityId,
    String? timeSlotId,
    required DateTime bookingDate,
    required int participantCount,
    required bool isMemberBooking,
    required double totalPrice,
    required int expectedPoints,
    Map<String, dynamic>? metadata,
    String? voucherId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to book');
    }

    try {
      /// Atomic transaction ensures overbooking prevention and data consistency
      final booking = await _firestore.runTransaction<Booking>((
        transaction,
      ) async {
        /// Fetch activity data within transaction for consistent validation
        final activityRef = _firestore.collection('activities').doc(activityId);
        final activityDoc = await transaction.get(activityRef);

        if (!activityDoc.exists) {
          throw Exception('Activity not found');
        }

        final activityData = activityDoc.data()!;

        /// Voucher validation and discount calculation from user's purchased vouchers
        var voucherDiscount = 0.0;
        if (voucherId != null) {
          // Read from user's purchased vouchers subcollection
          final voucherRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('user_vouchers')
              .doc(voucherId);
          final voucherDoc = await transaction.get(voucherRef);

          if (!voucherDoc.exists) {
            throw Exception('Voucher not found');
          }

          final voucher = Voucher.fromFirestore(voucherDoc);

          /// Business rule validation for voucher usage
          if (!voucher.canBeUsedForBookings) {
            throw Exception('This voucher cannot be used for bookings');
          }

          if (voucher.purchasedBy != user.uid) {
            throw Exception('You do not own this voucher');
          }

          if (voucher.clubId != activityData['clubId']) {
            throw Exception(
              'This voucher can only be used for activities from ${voucher.clubName}',
            );
          }

          final allowVouchers = activityData['allowVouchers'] ?? true;
          if (!allowVouchers) {
            throw Exception('Vouchers are not allowed for this activity');
          }

          voucherDiscount = voucher.amount;

          /// Mark voucher instance as consumed in the transaction
          transaction.update(voucherRef, {
            'usedAt': Timestamp.fromDate(DateTime.now()),
            'usedForBooking': activityId,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }

        /// Calculate final payment and points based on actual amount paid
        final finalAmountPaid = (totalPrice - voucherDiscount).clamp(
          0.0,
          totalPrice,
        );
        final finalPointsEarned = calculatePointsEarned(
          Activity.fromJson(activityData),
          finalAmountPaid,
          isMemberBooking,
        );

        /// Capacity validation to prevent overbooking
        final capacity = activityData['capacity'] ?? 0;
        final bookedCount = activityData['bookedCount'] ?? 0;

        if (bookedCount + participantCount > capacity) {
          throw Exception('No available capacity for this booking');
        }

        /// Extract denormalized data for booking record and notifications
        final activityTitle = activityData['name'] ?? 'Unknown Activity';
        final clubId = activityData['clubId'] ?? '';
        final clubName = activityData['clubName'] ?? '';
        final facilityId = activityData['facilityId'] ?? '';
        final facilityName = activityData['facilityName'] ?? '';

        /// Safe date/time parsing with fallback handling
        DateTime activityDateTime;
        try {
          final dateField = activityData['date'];
          if (dateField is Timestamp) {
            activityDateTime = dateField.toDate();
          } else if (dateField is String) {
            activityDateTime = DateTime.parse(dateField);
          } else {
            activityDateTime = DateTime.now();
          }
        } catch (e) {
          activityDateTime = DateTime.now();
        }

        final activityTime = activityData['time'] ?? '00:00';

        /// Combine date and time for precise scheduling and notification timing
        DateTime scheduledDateTime;
        try {
          final timeParts = activityTime.split(':');
          scheduledDateTime = DateTime(
            activityDateTime.year,
            activityDateTime.month,
            activityDateTime.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        } catch (e) {
          scheduledDateTime = activityDateTime;
        }

        /// Transaction writes: Update capacity and create booking atomically

        /// Reduce available capacity immediately upon booking confirmation
        final newBookedCount = bookedCount + participantCount;
        final newSpotsLeft = capacity - newBookedCount;

        transaction.update(activityRef, {
          'bookedCount': newBookedCount,
          'spotsLeft': newSpotsLeft,
        });

        /// Create comprehensive booking record with denormalized data
        final bookingRef = _firestore.collection('bookings').doc();
        final confirmationNumber = _generateConfirmationNumber();

        final bookingData = {
          'id': bookingRef.id,
          'userId': user.uid,
          //'userName': userName,  // Store user display name
          //'userEmail': userEmail,  // Store user email
          'activityId': activityId,
          'timeSlotId': timeSlotId,
          'bookingDate': Timestamp.fromDate(bookingDate),
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'status': 'confirmed',
          'amountPaid': finalAmountPaid,
          'pointsEarned': finalPointsEarned,
          'participantCount': participantCount,
          'isMemberBooking': isMemberBooking,
          'cancellationReason': null,
          'cancelledAt': null,
          'confirmationNumber': confirmationNumber,
          'metadata': metadata,
          'voucherId': voucherId,
          'voucherDiscount': voucherDiscount > 0 ? voucherDiscount : null,
          'activityTitle': activityTitle,
          'activityDate': Timestamp.fromDate(activityDateTime),
          'activityTime': activityTime,
          'scheduledDate': Timestamp.fromDate(scheduledDateTime),
          'totalPrice': totalPrice,
          /// Denormalized club/facility data for efficient querying and display
          'clubId': clubId,
          'clubName': clubName,
          'facilityId': facilityId,
          'facilityName': facilityName,
          'activityName': activityTitle,
        };

        transaction.set(bookingRef, bookingData);

        /// Link voucher instance to specific booking ID for audit trail
        if (voucherId != null) {
          final voucherRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('user_vouchers')
              .doc(voucherId);
          transaction.update(voucherRef, {'usedForBooking': bookingRef.id});
        }

        /// Return booking object for immediate UI feedback
        return Booking(
          id: bookingRef.id,
          userId: user.uid,
          activityId: activityId,
          timeSlotId: timeSlotId,
          bookingDate: bookingDate,
          createdAt: DateTime.now(),
          status: BookingStatus.confirmed,
          amountPaid: finalAmountPaid,
          pointsEarned: finalPointsEarned,
          participantCount: participantCount,
          isMemberBooking: isMemberBooking,
          confirmationNumber: confirmationNumber,
          metadata: metadata,
          voucherId: voucherId,
          voucherDiscount: voucherDiscount > 0 ? voucherDiscount : null,
          activityTitle: activityTitle,
          activityDate: activityDateTime,
          activityTime: activityTime,
          totalPrice: totalPrice,
          clubId: clubId,
          clubName: clubName,
          facilityId: facilityId,
          facilityName: facilityName,
        );
      });

      /// Create user booking reference for efficient user-specific queries
      /// Points are credited only when booking status changes to 'completed'
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .doc(booking.id)
          .set({
            'bookingId': booking.id,
            'activityId': activityId,
            'bookingDate': Timestamp.fromDate(bookingDate),
            'status': 'confirmed',
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });

      return booking;
    } catch (e) {
      if (e.toString().contains('transaction')) {}
      rethrow;
    }
  }

  /// Cancel existing booking with capacity restoration and authorization validation
  static Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be authenticated');

    try {
      /// Retrieve booking for validation and capacity restoration
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final booking = Booking.fromFirestore(bookingDoc);

      /// Authorization: only booking owner can cancel
      if (booking.userId != user.uid) {
        throw Exception('Unauthorized to cancel this booking');
      }

      /// Business rule: only certain statuses allow cancellation
      if (!booking.canBeCancelled) {
        throw Exception(
          'This booking cannot be cancelled (current status: ${booking.status})',
        );
      }

      /// Update booking status with cancellation metadata
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });

      /// Restore activity capacity for future bookings
      try {
        final activityRef = _firestore
            .collection('activities')
            .doc(booking.activityId);
        final activityDoc = await activityRef.get();

        if (activityDoc.exists) {
          final activityData = activityDoc.data()!;

          final currentBookedCount =
              (activityData['bookedCount'] as num?)?.toInt() ?? 0;
          final capacity = (activityData['capacity'] as num?)?.toInt() ?? 0;

          if (capacity > 0) {
            /// Return cancelled spots to available capacity
            final newBookedCount =
                (currentBookedCount - booking.participantCount).clamp(
                  0,
                  capacity,
                );
            final newSpotsLeft = capacity - newBookedCount;

            await activityRef.update({
              'bookedCount': newBookedCount,
              'spotsLeft': newSpotsLeft,
            });
          }
        }
      } catch (e) {
        /// Non-critical: booking cancellation succeeded even if capacity update failed
      }

      /// Note: Points are never credited for cancelled bookings (only on 'completed' status)

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark user booking as completed by club owner and award points
  /// This method allows club owners to complete bookings for their activities
  /// while properly crediting points to participants
  static Future<bool> markUserBookingCompleted(String bookingId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User must be authenticated');

    try {
      // Get booking document first
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final booking = Booking.fromFirestore(bookingDoc);

      // Verify club owner authorization
      // Get the activity to check club ownership
      final activityDoc = await _firestore
          .collection('activities')
          .doc(booking.activityId)
          .get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activityData = activityDoc.data()!;
      final clubId = activityData['clubId'] as String?;

      if (clubId == null) {
        throw Exception('Activity not associated with a club');
      }

      // Verify current user owns the club
      final clubDoc = await _firestore
          .collection('clubs')
          .doc(clubId)
          .get();

      if (!clubDoc.exists) {
        throw Exception('Club not found');
      }

      final clubData = clubDoc.data()!;
      final clubOwnerId = clubData['ownerId'] as String?;

      if (clubOwnerId != currentUser.uid) {
        throw Exception('Unauthorized: You do not own this club');
      }

      // Business rule: only confirmed bookings can be completed
      if (booking.status != BookingStatus.confirmed) {
        throw Exception(
          'Only confirmed bookings can be completed (current status: ${booking.status})',
        );
      }

      // Update booking status to completed
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.completed.value,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'completedBy': currentUser.uid, // Track who marked it as completed
      });

      // Credit earned points to user's account
      if (booking.pointsEarned > 0) {
        final userRef = _firestore.collection('users').doc(booking.userId);

        await userRef.set({
          'availablePoints': FieldValue.increment(booking.pointsEarned),
          'lifetimePointsEarned': FieldValue.increment(booking.pointsEarned),
          'lastRewardUpdateAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Create audit trail for points transactions
        await userRef.collection('rewards_ledger').doc().set({
          'type': 'earn',
          'amount': booking.pointsEarned,
          'bookingId': booking.id,
          'activityId': booking.activityId,
          'activityTitle': booking.activityTitle,
          'awardedBy': currentUser.uid, // Track club owner who awarded points
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Original method for user self-completion (kept for backward compatibility)
  /// Mark booking as completed and credit reward points to user account
  /// Called after activity participation to activate points reward system
  static Future<bool> completeBooking(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be authenticated');

    try {
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final booking = Booking.fromFirestore(bookingDoc);

      /// Authorization validation for booking completion
      if (booking.userId != user.uid) {
        throw Exception('Unauthorized to complete this booking');
      }

      /// Business rule: only confirmed bookings can be completed
      if (booking.status != BookingStatus.confirmed) {
        throw Exception(
          'Only confirmed bookings can be completed (current status: ${booking.status})',
        );
      }

      /// Update booking status to trigger points crediting
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.completed.value,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      /// Credit earned points to user's reward account
      if (booking.pointsEarned > 0) {
        final userRef = _firestore.collection('users').doc(user.uid);

        await userRef.set({
          'availablePoints': FieldValue.increment(booking.pointsEarned),
          'lifetimePointsEarned': FieldValue.increment(booking.pointsEarned),
          'lastRewardUpdateAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        /// Create audit trail for points transactions
        await userRef.collection('rewards_ledger').doc().set({
          'type': 'earn',
          'amount': booking.pointsEarned,
          'bookingId': booking.id,
          'activityId': booking.activityId,
          'activityTitle': booking.activityTitle,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Real-time user booking history with automatic sorting
  static Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs.map(Booking.fromFirestore).toList();

          /// Sort by creation date for consistent UI display (newest first)
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return bookings;
        });
  }

  /// Retrieve specific booking details for confirmation and management
  static Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return doc.exists ? Booking.fromFirestore(doc) : null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate booking price based on membership status and group size
  static double calculatePrice(
    Activity activity,
    bool isMember,
    int participantCount,
  ) {
    final basePrice = isMember ? activity.memberPrice : activity.guestPrice;
    return basePrice * participantCount;
  }

  /// Apply voucher discount with price floor protection
  static double calculateFinalPrice(
    double originalPrice,
    double voucherDiscount,
  ) {
    return (originalPrice - voucherDiscount).clamp(0.0, originalPrice);
  }

  /// Comprehensive points calculation with member bonuses and category multipliers
  /// Points are earned only on the actual amount paid (after voucher discount)
  static int calculatePointsEarned(
    Activity activity,
    double paidAmount,
    bool isMember,
  ) {
    /// Get the original price that was used to set the points reward
    final originalPrice = isMember ? activity.memberPrice : activity.guestPrice;
    
    /// Base points from activity creation (e.g., 200 points)
    final originalPoints = activity.pointsReward;
    
    /// Calculate the percentage of original price that was actually paid
    final paymentRatio = originalPrice > 0 ? (paidAmount / originalPrice) : 0.0;
    
    /// Points earned = original points × payment ratio
    /// Example: 200 points × 0.5 (half paid) = 100 points
    var earnedPoints = (originalPoints * paymentRatio).round();
    
    /// Member benefit does NOT change points (as per your requirement)
    /// Category multipliers also should NOT apply since points are set by activity
    
    return earnedPoints;
  }

  /// Generate unique confirmation numbers for customer service and tracking
  static String _generateConfirmationNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'SC$random';
  }

  /// Detect scheduling conflicts to prevent double-booking users
  static Future<bool> hasConflictingBookings(
    String userId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              BookingStatus.confirmed.value,
              BookingStatus.pending.value,
            ],
          )
          .get();

      for (final doc in querySnapshot.docs) {
        final booking = Booking.fromFirestore(doc);

        /// Cross-reference with activity timing for overlap detection
        final activityDoc = await _firestore
            .collection('activities')
            .doc(booking.activityId)
            .get();

        if (activityDoc.exists) {
          final activityData = activityDoc.data()!;
          final activityStart = (activityData['startTime'] as Timestamp)
              .toDate();
          final activityEnd = (activityData['endTime'] as Timestamp).toDate();

          /// Time overlap detection for conflict prevention
          if (startTime.isBefore(activityEnd) &&
              endTime.isAfter(activityStart)) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Retrieve user's upcoming activities for calendar integration and notifications
  static Future<List<Booking>> getUpcomingBookings(String userId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('bookingDate', isGreaterThan: Timestamp.fromDate(now))
          .where(
            'status',
            whereIn: [
              BookingStatus.confirmed.value,
              BookingStatus.pending.value,
            ],
          )
          .orderBy('bookingDate')
          .get();

      return querySnapshot.docs.map(Booking.fromFirestore).toList();
    } catch (e) {
      return [];
    }
  }

  /// Administrative function to mark booking completion (typically automated)
  static Future<bool> markBookingCompleted(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.completed.value,
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
