import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Booking status enumeration
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  waitlist
}

/// Extension to convert BookingStatus to/from string
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

/// Time slot model for activity scheduling
class TimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final int bookedCount;
  final bool isAvailable;

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

  /// Check if time slot has available spots
  bool get hasAvailableSpots => isAvailable && bookedCount < capacity;

  /// Get remaining spots
  int get remainingSpots => capacity - bookedCount;

  /// Get formatted time range
  String get timeRange {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

/// Enhanced booking model
class Booking {
  final String id;
  final String userId;
  final String activityId;
  final String? timeSlotId;
  final DateTime bookingDate;
  final DateTime createdAt;
  final BookingStatus status;
  final double amountPaid;
  final int pointsEarned;
  final int participantCount;
  final bool isMemberBooking;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String confirmationNumber;
  final Map<String, dynamic>? metadata;
  
  // Activity details for display
  final String activityTitle;
  final DateTime activityDate;
  final String activityTime;
  final double totalPrice;

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
    required this.activityTitle,
    required this.activityDate,
    required this.activityTime,
    required this.totalPrice,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
      activityTitle: data['activityTitle'] ?? 'Unknown Activity',
      activityDate: data['activityDate'] != null 
          ? (data['activityDate'] as Timestamp).toDate()
          : (data['bookingDate'] as Timestamp).toDate(),
      activityTime: data['activityTime'] ?? '00:00',
      totalPrice: (data['totalPrice'] ?? data['amountPaid'] ?? 0.0).toDouble(),
    );
  }

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
      activityTitle: json['activityTitle'] ?? 'Unknown Activity',
      activityDate: json['activityDate'] != null 
          ? DateTime.parse(json['activityDate'])
          : DateTime.parse(json['bookingDate']),
      activityTime: json['activityTime'] ?? '00:00',
      totalPrice: (json['totalPrice'] ?? json['amountPaid'] ?? 0.0).toDouble(),
    );
  }

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
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'confirmationNumber': confirmationNumber,
      'metadata': metadata,
      'activityTitle': activityTitle,
      'activityDate': Timestamp.fromDate(activityDate),
      'activityTime': activityTime,
      'totalPrice': totalPrice,
    };
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return status == BookingStatus.confirmed || status == BookingStatus.pending;
  }

  /// Check if booking is active
  bool get isActive {
    return status == BookingStatus.confirmed || status == BookingStatus.pending;
  }

  /// Get status display text
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

  /// Get status color for UI
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

/// Booking details model for the booking flow
class BookingDetails {
  final String activityId;
  final String? timeSlotId;
  final DateTime bookingDate;
  final int participantCount;
  final bool isMemberBooking;
  final double totalPrice;
  final int expectedPoints;
  final Map<String, dynamic>? additionalInfo;

  BookingDetails({
    required this.activityId,
    this.timeSlotId,
    required this.bookingDate,
    required this.participantCount,
    required this.isMemberBooking,
    required this.totalPrice,
    required this.expectedPoints,
    this.additionalInfo,
  });

  BookingDetails copyWith({
    String? activityId,
    String? timeSlotId,
    DateTime? bookingDate,
    int? participantCount,
    bool? isMemberBooking,
    double? totalPrice,
    int? expectedPoints,
    Map<String, dynamic>? additionalInfo,
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
    );
  }
}