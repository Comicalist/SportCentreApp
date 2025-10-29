import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking.dart';

/// Participant model for admin management
/// Combines booking and user information for event participant management
class Participant {
  final String id; // Booking ID
  final String userId;
  final String userName;
  final String userEmail;
  final String activityId;
  final String activityTitle;
  final DateTime activityDate;
  final String activityTime;
  final DateTime bookingDate;
  final BookingStatus status;
  final int participantCount;
  final double amountPaid;
  final int pointsEarned;
  final bool isMemberBooking;
  final String confirmationNumber;
  final String? phoneNumber;
  final String? notes;

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

  /// Create from Firestore booking document with user data
  factory Participant.fromFirestore(
    DocumentSnapshot bookingDoc,
    Map<String, dynamic> userData,
  ) {
    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    
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
      status: BookingStatusExtension.fromString(bookingData['status'] ?? 'pending'),
      participantCount: bookingData['participantCount'] ?? 1,
      amountPaid: (bookingData['amountPaid'] ?? 0).toDouble(),
      pointsEarned: bookingData['pointsEarned'] ?? 0,
      isMemberBooking: bookingData['isMemberBooking'] ?? false,
      confirmationNumber: bookingData['confirmationNumber'] ?? '',
      phoneNumber: userData['phoneNumber'],
      notes: bookingData['notes'],
    );
  }

  /// Helper method to parse DateTime from various Firestore formats
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

  /// Convert to JSON for Firestore updates
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

  /// Create a copy with updated fields
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

  /// Get status display text
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

  /// Get member type display
  String get memberType => isMemberBooking ? 'Member' : 'Guest';

  /// Format activity date for display
  String get formattedActivityDate {
    return '${activityDate.day}/${activityDate.month}/${activityDate.year}';
  }

  /// Format booking date for display
  String get formattedBookingDate {
    return '${bookingDate.day}/${bookingDate.month}/${bookingDate.year} ${bookingDate.hour}:${bookingDate.minute.toString().padLeft(2, '0')}';
  }
}
