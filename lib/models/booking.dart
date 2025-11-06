import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Booking lifecycle states for activity reservations
enum BookingStatus { pending, confirmed, cancelled, completed, waitlist }

/// Extension for BookingStatus serialization and display
extension BookingStatusExtension on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.waitlist:
        return 'waitlist';
    }
  }

  String get displayName {
    switch (this) {
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

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'waitlist':
        return BookingStatus.waitlist;
      default:
        return BookingStatus.pending;
    }
  }
}

/// Time slot configuration for activities with capacity management
/// 
/// Represents specific time windows when activities can be booked,
/// tracking capacity limits and current booking counts for availability
class TimeSlot {
  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.bookedCount,
    required this.isAvailable,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      capacity: json['capacity'] ?? 0,
      bookedCount: json['bookedCount'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity; // Maximum participants allowed
  final int bookedCount; // Current bookings
  final bool isAvailable; // Admin can disable slots

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'capacity': capacity,
      'bookedCount': bookedCount,
      'isAvailable': isAvailable,
    };
  }

  /// Check if new bookings can be accepted
  bool get hasAvailableSpots => isAvailable && bookedCount < capacity;

  /// Calculate remaining capacity
  int get remainingSpots => capacity - bookedCount;

  /// Format time range for display (e.g., "09:00 - 10:30")
  String get timeRange {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

/// Activity booking with financial tracking and voucher support
/// 
/// Represents a user's reservation for an activity, including payment details,
/// points earned, voucher usage, and lifecycle management from creation to completion
class Booking {
  Booking({
    required this.id,
    required this.userId,
    required this.activityId,
    this.timeSlotId,
    required this.bookingDate,
    required this.createdAt,
    required this.status,
    required this.amountPaid,
    required this.pointsEarned,
    required this.participantCount,
    required this.isMemberBooking,
    this.cancellationReason,
    this.cancelledAt,
    required this.confirmationNumber,
    this.metadata,
    this.voucherId,
    this.voucherDiscount,
    required this.activityTitle,
    required this.activityDate,
    required this.activityTime,
    required this.totalPrice,
    required this.clubId,
    required this.clubName,
    required this.facilityId,
    required this.facilityName,
  });

  /// Create Booking from Firestore document with type conversions
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      activityId: data['activityId'] ?? '',
      timeSlotId: data['timeSlotId'],
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: BookingStatusExtension.fromString(data['status'] ?? 'pending'),
      amountPaid: (data['amountPaid'] ?? 0.0).toDouble(),
      pointsEarned: data['pointsEarned'] ?? 0,
      participantCount: data['participantCount'] ?? 1,
      isMemberBooking: data['isMemberBooking'] ?? false,
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      confirmationNumber: data['confirmationNumber'] ?? '',
      metadata: data['metadata'],
      voucherId: data['voucherId'],
      voucherDiscount: data['voucherDiscount']?.toDouble(),
      activityTitle: data['activityTitle'] ?? 'Unknown Activity',
      activityDate: data['activityDate'] != null
          ? (data['activityDate'] as Timestamp).toDate()
          : (data['bookingDate'] as Timestamp).toDate(),
      activityTime: data['activityTime'] ?? '00:00',
      totalPrice: (data['totalPrice'] ?? data['amountPaid'] ?? 0.0).toDouble(),
      clubId: data['clubId'] ?? '',
      clubName: data['clubName'] ?? '',
      facilityId: data['facilityId'] ?? '',
      facilityName: data['facilityName'] ?? '',
    );
  }

  /// Create Booking from JSON with date parsing
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      activityId: json['activityId'] ?? '',
      timeSlotId: json['timeSlotId'],
      bookingDate: DateTime.parse(json['bookingDate']),
      createdAt: DateTime.parse(json['createdAt']),
      status: BookingStatusExtension.fromString(json['status'] ?? 'pending'),
      amountPaid: (json['amountPaid'] ?? 0.0).toDouble(),
      pointsEarned: json['pointsEarned'] ?? 0,
      participantCount: json['participantCount'] ?? 1,
      isMemberBooking: json['isMemberBooking'] ?? false,
      cancellationReason: json['cancellationReason'],
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      confirmationNumber: json['confirmationNumber'] ?? '',
      metadata: json['metadata'],
      voucherId: json['voucherId'],
      voucherDiscount: json['voucherDiscount']?.toDouble(),
      activityTitle: json['activityTitle'] ?? 'Unknown Activity',
      activityDate: json['activityDate'] != null
          ? DateTime.parse(json['activityDate'])
          : DateTime.parse(json['bookingDate']),
      activityTime: json['activityTime'] ?? '00:00',
      totalPrice: (json['totalPrice'] ?? json['amountPaid'] ?? 0.0).toDouble(),
      clubId: json['clubId'] ?? '',
      clubName: json['clubName'] ?? '',
      facilityId: json['facilityId'] ?? '',
      facilityName: json['facilityName'] ?? '',
    );
  }

  // Core booking identifiers
  final String id;
  final String userId;
  final String activityId;
  final String? timeSlotId;

  // Booking lifecycle
  final DateTime bookingDate; // When booking was made
  final DateTime createdAt;
  final BookingStatus status;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String confirmationNumber; // For customer reference

  // Financial details
  final double amountPaid; // Actual amount charged (after voucher discount)
  final double totalPrice; // Original price before discounts
  final int pointsEarned; // Reward points (only credited on completion)

  // Booking configuration
  final int participantCount;
  final bool isMemberBooking; // Affects pricing and points
  final Map<String, dynamic>? metadata; // Additional booking data

  // Voucher integration
  final String? voucherId; // Voucher used for discount
  final double? voucherDiscount; // Amount discounted

  // Denormalized activity data (for display without additional queries)
  final String activityTitle;
  final DateTime activityDate; // When activity takes place
  final String activityTime;
  final String clubId;
  final String clubName;
  final String facilityId;
  final String facilityName;

  /// Convert to Firestore format with Timestamps
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'timeSlotId': timeSlotId,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.value,
      'amountPaid': amountPaid,
      'pointsEarned': pointsEarned,
      'participantCount': participantCount,
      'isMemberBooking': isMemberBooking,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'confirmationNumber': confirmationNumber,
      'metadata': metadata,
      'voucherId': voucherId,
      'voucherDiscount': voucherDiscount,
      'activityTitle': activityTitle,
      'activityDate': Timestamp.fromDate(activityDate),
      'activityTime': activityTime,
      'totalPrice': totalPrice,
      'clubId': clubId,
      'clubName': clubName,
      'facilityId': facilityId,
      'facilityName': facilityName,
    };
  }

  /// Check if booking can be cancelled (confirmed/pending only)
  bool get canBeCancelled {
    return status == BookingStatus.confirmed || status == BookingStatus.pending;
  }

  /// Check if booking is in active state
  bool get isActive {
    return status == BookingStatus.confirmed || status == BookingStatus.pending;
  }

  /// Get user-friendly status text
  String get statusDisplayText {
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
        return 'Waitlisted';
    }
  }

  /// Get status color for UI badges
  Color get statusColor {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.teal;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.grey;
      case BookingStatus.waitlist:
        return Colors.blue;
    }
  }
}

/// Booking flow data model for UI state management
/// 
/// Temporary model used during the booking process to collect user choices
/// before creating the final Booking entity
class BookingDetails {
  BookingDetails({
    required this.activityId,
    this.timeSlotId,
    required this.bookingDate,
    required this.participantCount,
    required this.isMemberBooking,
    required this.totalPrice,
    required this.expectedPoints,
    this.additionalInfo,
    this.voucherId,
    this.voucherDiscount,
  });

  final String activityId;
  final String? timeSlotId;
  final DateTime bookingDate;
  final int participantCount;
  final bool isMemberBooking;
  final double totalPrice; // Before voucher discount
  final int expectedPoints; // Estimated points to earn
  final Map<String, dynamic>? additionalInfo;

  // Voucher selection
  final String? voucherId;
  final double? voucherDiscount;

  /// Create updated copy with new values
  BookingDetails copyWith({
    String? activityId,
    String? timeSlotId,
    DateTime? bookingDate,
    int? participantCount,
    bool? isMemberBooking,
    double? totalPrice,
    int? expectedPoints,
    Map<String, dynamic>? additionalInfo,
    String? voucherId,
    double? voucherDiscount,
  }) {
    return BookingDetails(
      activityId: activityId ?? this.activityId,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      bookingDate: bookingDate ?? this.bookingDate,
      participantCount: participantCount ?? this.participantCount,
      isMemberBooking: isMemberBooking ?? this.isMemberBooking,
      totalPrice: totalPrice ?? this.totalPrice,
      expectedPoints: expectedPoints ?? this.expectedPoints,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      voucherId: voucherId ?? this.voucherId,
      voucherDiscount: voucherDiscount ?? this.voucherDiscount,
    );
  }
}
