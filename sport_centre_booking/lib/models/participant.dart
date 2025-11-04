import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking.dart';

/// Admin view model combining booking and user data for participant management
/// 
/// Aggregates booking information with user details to provide club owners
/// and admins with comprehensive participant lists for activities. Enables
/// efficient management of attendees, contact information, and booking status.
class Participant {
  Participant({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.activityId,
    required this.activityTitle,
    required this.activityDate,
    required this.activityTime,
    required this.bookingDate,
    required this.status,
    required this.participantCount,
    required this.amountPaid,
    required this.pointsEarned,
    required this.isMemberBooking,
    required this.confirmationNumber,
    this.phoneNumber,
    this.notes,
  });

  /// Create participant from booking document and user profile data
  /// Merges Firestore booking with user information for admin views
  factory Participant.fromFirestore(
    DocumentSnapshot bookingDoc,
    Map<String, dynamic> userData,
  ) {
    final bookingData = bookingDoc.data()! as Map<String, dynamic>;

    return Participant(
      id: bookingDoc.id,
      userId: bookingData['userId'] ?? '',
      userName: userData['name'] ?? 'Unknown User',
      userEmail: userData['email'] ?? '',
      activityId: bookingData['activityId'] ?? '',
      activityTitle: bookingData['activityTitle'] ?? 'Unknown Activity',
      activityDate: _parseDateTime(bookingData['activityDate']),
      activityTime: bookingData['activityTime'] ?? '',
      bookingDate: _parseDateTime(bookingData['bookingDate']),
      status: BookingStatusExtension.fromString(
        bookingData['status'] ?? 'pending',
      ),
      participantCount: bookingData['participantCount'] ?? 1,
      amountPaid: (bookingData['amountPaid'] ?? 0).toDouble(),
      pointsEarned: bookingData['pointsEarned'] ?? 0,
      isMemberBooking: bookingData['isMemberBooking'] ?? false,
      confirmationNumber: bookingData['confirmationNumber'] ?? '',
      phoneNumber: userData['phoneNumber'],
      notes: bookingData['notes'],
    );
  }

  // Booking reference
  final String id; // Booking ID for updates
  final String activityId;
  final String confirmationNumber; // Customer reference

  // User identification and contact
  final String userId;
  final String userName; // Display name for participant lists
  final String userEmail; // Primary contact method
  final String? phoneNumber; // Secondary contact (optional)

  // Activity details (denormalized for admin convenience)
  final String activityTitle;
  final DateTime activityDate; // When activity occurs
  final String activityTime; // Time slot

  // Booking details
  final DateTime bookingDate; // When reservation was made
  final BookingStatus status; // Current booking state
  final int participantCount; // Number of people in this booking
  final bool isMemberBooking; // Member vs guest pricing applied

  // Financial tracking
  final double amountPaid; // Revenue from this booking
  final int pointsEarned; // Loyalty points awarded

  // Additional information
  final String? notes; // Special requirements or admin notes

  /// Safely parse DateTime from various Firestore data formats
  static DateTime _parseDateTime(dynamic dateField) {
    if (dateField == null) return DateTime.now();

    if (dateField is Timestamp) {
      return dateField.toDate();
    } else if (dateField is String) {
      return DateTime.parse(dateField);
    } else if (dateField is DateTime) {
      return dateField;
    }

    return DateTime.now();
  }

  /// Convert to Firestore format for booking updates
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activityId': activityId,
      'activityTitle': activityTitle,
      'activityDate': Timestamp.fromDate(activityDate),
      'activityTime': activityTime,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'status': status.value,
      'participantCount': participantCount,
      'amountPaid': amountPaid,
      'pointsEarned': pointsEarned,
      'isMemberBooking': isMemberBooking,
      'confirmationNumber': confirmationNumber,
      'notes': notes,
    };
  }

  /// Create updated participant with modified fields
  Participant copyWith({
    String? userName,
    String? userEmail,
    String? activityTitle,
    DateTime? activityDate,
    String? activityTime,
    BookingStatus? status,
    int? participantCount,
    double? amountPaid,
    int? pointsEarned,
    bool? isMemberBooking,
    String? phoneNumber,
    String? notes,
  }) {
    return Participant(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      activityId: activityId,
      activityTitle: activityTitle ?? this.activityTitle,
      activityDate: activityDate ?? this.activityDate,
      activityTime: activityTime ?? this.activityTime,
      bookingDate: bookingDate,
      status: status ?? this.status,
      participantCount: participantCount ?? this.participantCount,
      amountPaid: amountPaid ?? this.amountPaid,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      isMemberBooking: isMemberBooking ?? this.isMemberBooking,
      confirmationNumber: confirmationNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
    );
  }

  /// Get human-readable booking status for admin displays
  String get statusDisplay {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.waitlist:
        return 'Waitlist';
    }
  }

  /// Get member classification for pricing context
  String get memberType => isMemberBooking ? 'Member' : 'Guest';

  /// Format activity date for participant lists (DD/MM/YYYY)
  String get formattedActivityDate {
    return '${activityDate.day}/${activityDate.month}/${activityDate.year}';
  }

  /// Format booking timestamp for admin tracking (DD/MM/YYYY HH:MM)
  String get formattedBookingDate {
    return '${bookingDate.day}/${bookingDate.month}/${bookingDate.year} ${bookingDate.hour}:${bookingDate.minute.toString().padLeft(2, '0')}';
  }
}
