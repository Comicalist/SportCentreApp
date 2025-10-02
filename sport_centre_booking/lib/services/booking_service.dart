import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../models/activity.dart';

/// Service for managing booking operations
class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if a time slot is available for booking
  static Future<bool> checkAvailability(String activityId, String? timeSlotId) async {
    try {
      final activityDoc = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();

      if (!activityDoc.exists) return false;

      final activityData = activityDoc.data()!;
      
      // If no specific time slot, check general activity availability
      if (timeSlotId == null) {
        final capacity = activityData['capacity'] ?? 0;
        final bookedCount = activityData['bookedCount'] ?? 0;
        return bookedCount < capacity;
      }

      // Check specific time slot availability
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
      print('Error checking availability: $e');
      return false;
    }
  }

  /// Create a new booking with transaction for consistency
  static Future<Booking?> createBooking({
    required String activityId,
    String? timeSlotId,
    required DateTime bookingDate,
    required int participantCount,
    required bool isMemberBooking,
    required double totalPrice,
    required int expectedPoints,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Error: User must be authenticated to book');
      throw Exception('User must be authenticated to book');
    }

    print('Creating booking for activity: $activityId, user: ${user.uid}');

    try {
      // Use transaction to ensure data consistency and prevent overbooking
      return await _firestore.runTransaction<Booking?>((transaction) async {
        print('Starting transaction for booking creation');
        
        // Get activity data within transaction
        final activityRef = _firestore.collection('activities').doc(activityId);
        final activityDoc = await transaction.get(activityRef);

        if (!activityDoc.exists) {
          print('Error: Activity not found: $activityId');
          throw Exception('Activity not found');
        }

        final activityData = activityDoc.data()!;
        print('Activity data loaded: ${activityData['name']}');
        
        // Check capacity and update bookings count
        final capacity = activityData['capacity'] ?? 0;
        final bookedCount = activityData['bookedCount'] ?? 0;
        
        print('Checking capacity: $bookedCount/$capacity, requesting: $participantCount');
        
        if (bookedCount + participantCount > capacity) {
          print('Error: No available capacity for this booking');
          throw Exception('No available capacity for this booking');
        }

        // Extract activity details for the booking
        final activityTitle = activityData['name'] ?? 'Unknown Activity';
        
        // Handle date conversion safely
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
          print('Error parsing activity date: $e');
          activityDateTime = DateTime.now();
        }
        
        final activityTime = activityData['time'] ?? '00:00';
        
        print('Activity details: $activityTitle, Date: $activityDateTime, Time: $activityTime');

        // Update activity capacity first
        print('Updating activity capacity...');
        final newBookedCount = bookedCount + participantCount;
        final newSpotsLeft = capacity - newBookedCount;
        
        transaction.update(activityRef, {
          'bookedCount': newBookedCount,
          'spotsLeft': newSpotsLeft,
        });

        // Create booking document
        print('Creating booking document...');
        final bookingRef = _firestore.collection('bookings').doc();
        final confirmationNumber = _generateConfirmationNumber();
        
        // Create booking data directly instead of using toJson() to avoid serialization issues
        final bookingData = {
          'id': bookingRef.id,
          'userId': user.uid,
          'activityId': activityId,
          'timeSlotId': timeSlotId,
          'bookingDate': Timestamp.fromDate(bookingDate),
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'status': 'confirmed',
          'amountPaid': totalPrice,
          'pointsEarned': expectedPoints,
          'participantCount': participantCount,
          'isMemberBooking': isMemberBooking,
          'cancellationReason': null,
          'cancelledAt': null,
          'confirmationNumber': confirmationNumber,
          'metadata': metadata,
          'activityTitle': activityTitle,
          'activityDate': Timestamp.fromDate(activityDateTime),
          'activityTime': activityTime,
          'totalPrice': totalPrice,
        };

        print('Booking data prepared, saving to Firestore...');
        transaction.set(bookingRef, bookingData);

        // Create user booking reference for easy querying
        print('Creating user booking reference...');
        final userBookingRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookings')
            .doc(bookingRef.id);
        
        transaction.set(userBookingRef, {
          'bookingId': bookingRef.id,
          'activityId': activityId,
          'bookingDate': Timestamp.fromDate(bookingDate),
          'status': 'confirmed',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // Create Booking object to return
        final booking = Booking(
          id: bookingRef.id,
          userId: user.uid,
          activityId: activityId,
          timeSlotId: timeSlotId,
          bookingDate: bookingDate,
          createdAt: DateTime.now(),
          status: BookingStatus.confirmed,
          amountPaid: totalPrice,
          pointsEarned: expectedPoints,
          participantCount: participantCount,
          isMemberBooking: isMemberBooking,
          confirmationNumber: confirmationNumber,
          metadata: metadata,
          activityTitle: activityTitle,
          activityDate: activityDateTime,
          activityTime: activityTime,
          totalPrice: totalPrice,
        );

        print('Booking transaction completed successfully');
        return booking;
      });
    } catch (e) {
      print('Error creating booking: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('transaction')) {
        print('Transaction-specific error details: $e');
      }
      rethrow;
    }
  }

  /// Cancel a booking
  static Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be authenticated');

    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get booking
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking not found');
        }

        final booking = Booking.fromFirestore(bookingDoc);

        // Check if user owns this booking
        if (booking.userId != user.uid) {
          throw Exception('Unauthorized to cancel this booking');
        }

        // Check if booking can be cancelled
        if (!booking.canBeCancelled) {
          throw Exception('This booking cannot be cancelled');
        }

        // Update booking status
        transaction.update(bookingRef, {
          'status': BookingStatus.cancelled.value,
          'cancellationReason': reason,
          'cancelledAt': Timestamp.fromDate(DateTime.now()),
        });

        // Update activity/time slot capacity
        final activityRef = _firestore.collection('activities').doc(booking.activityId);
        final activityDoc = await transaction.get(activityRef);

        if (activityDoc.exists) {
          final activityData = activityDoc.data()!;
          Map<String, dynamic> updateData = {};

          if (booking.timeSlotId == null) {
            // General activity booking
            final bookedCount = activityData['bookedCount'] ?? 0;
            updateData['bookedCount'] = (bookedCount - booking.participantCount).clamp(0, double.infinity);
          } else {
            // Specific time slot booking
            final timeSlots = List<Map<String, dynamic>>.from(
              activityData['timeSlots'] ?? []
            );
            
            final timeSlotIndex = timeSlots.indexWhere(
              (slot) => slot['id'] == booking.timeSlotId
            );
            
            if (timeSlotIndex != -1) {
              final timeSlot = timeSlots[timeSlotIndex];
              final bookedCount = timeSlot['bookedCount'] ?? 0;
              timeSlots[timeSlotIndex]['bookedCount'] = 
                  (bookedCount - booking.participantCount).clamp(0, double.infinity);
              updateData['timeSlots'] = timeSlots;
            }
          }

          transaction.update(activityRef, updateData);
        }

        // Update user booking reference
        final userBookingRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookings')
            .doc(bookingId);
        
        transaction.update(userBookingRef, {
          'status': BookingStatus.cancelled.value,
        });

        return true;
      });
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  /// Get user bookings as a stream
  static Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
      
      // Sort by creation date (newest first) since we can't use orderBy without index
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return bookings;
    });
  }

  /// Get a specific booking
  static Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return doc.exists ? Booking.fromFirestore(doc) : null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  /// Calculate pricing based on member status and participant count
  static double calculatePrice(Activity activity, bool isMember, int participantCount) {
    final basePrice = isMember ? activity.memberPrice : activity.guestPrice;
    return basePrice * participantCount;
  }

  /// Calculate points earned based on activity and amount paid
  static int calculatePointsEarned(Activity activity, double paidAmount, bool isMember) {
    // Base points: 1 point per $1 spent
    int basePoints = paidAmount.floor();
    
    // Member bonus: 50% more points
    if (isMember) {
      basePoints = (basePoints * 1.5).floor();
    }

    // Activity type multiplier
    switch (activity.category.toLowerCase()) {
      case 'wellness':
        basePoints = (basePoints * 1.2).floor();
        break;
      case 'workshops':
        basePoints = (basePoints * 1.3).floor();
        break;
      default:
        break;
    }

    return basePoints;
  }

  /// Generate a unique confirmation number
  static String _generateConfirmationNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'SC$random';
  }

  /// Check if user has any conflicting bookings
  static Future<bool> hasConflictingBookings(
    String userId, 
    DateTime startTime, 
    DateTime endTime
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            BookingStatus.confirmed.value,
            BookingStatus.pending.value
          ])
          .get();

      for (final doc in querySnapshot.docs) {
        final booking = Booking.fromFirestore(doc);
        
        // Get activity details to check timing
        final activityDoc = await _firestore
            .collection('activities')
            .doc(booking.activityId)
            .get();
            
        if (activityDoc.exists) {
          final activityData = activityDoc.data()!;
          final activityStart = (activityData['startTime'] as Timestamp).toDate();
          final activityEnd = (activityData['endTime'] as Timestamp).toDate();
          
          // Check for time overlap
          if (startTime.isBefore(activityEnd) && endTime.isAfter(activityStart)) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking conflicting bookings: $e');
      return false;
    }
  }

  /// Get upcoming bookings for a user
  static Future<List<Booking>> getUpcomingBookings(String userId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('bookingDate', isGreaterThan: Timestamp.fromDate(now))
          .where('status', whereIn: [
            BookingStatus.confirmed.value,
            BookingStatus.pending.value
          ])
          .orderBy('bookingDate')
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting upcoming bookings: $e');
      return [];
    }
  }

  /// Mark booking as completed (typically called after activity ends)
  static Future<bool> markBookingCompleted(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.completed.value,
      });

      return true;
    } catch (e) {
      print('Error marking booking as completed: $e');
      return false;
    }
  }
}