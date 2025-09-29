class Booking {
  final String id;
  final String userId;
  final String activityId;
  final DateTime bookingDate;
  final String status; // 'confirmed', 'completed', 'cancelled'
  final double amountPaid;
  final int pointsEarned;

  Booking({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.bookingDate,
    required this.status,
    required this.amountPaid,
    required this.pointsEarned,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['userId'],
      activityId: json['activityId'],
      bookingDate: DateTime.parse(json['bookingDate']),
      status: json['status'],
      amountPaid: json['amountPaid'].toDouble(),
      pointsEarned: json['pointsEarned'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status,
      'amountPaid': amountPaid,
      'pointsEarned': pointsEarned,
    };
  }
}