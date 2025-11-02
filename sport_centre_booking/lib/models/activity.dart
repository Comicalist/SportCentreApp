class Activity {
  Activity({
    required this.id,
    required this.clubId,
    required this.facilityId,
    required this.clubName,
    required this.facilityName,
    required this.name,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    required this.duration,
    required this.timeCategory,
    required this.capacity,
    this.bookedCount = 0,
    required this.guestPrice,
    required this.memberPrice,
    required this.pointsReward,
    this.allowVouchers = true,
    this.requirements = const [],
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      facilityId: json['facilityId'] ?? '',
      clubName: json['clubName'] ?? '',
      facilityName: json['facilityName'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : (json['date'] as DateTime),
      time: json['time'] ?? '00:00',
      duration:
          json['duration'] ??
          60, // Default 60 minutes for backward compatibility
      timeCategory:
          json['timeCategory'] ?? getTimeCategory(json['time'] ?? '00:00'),
      capacity: json['capacity'] ?? 0,
      bookedCount: json['bookedCount'] ?? 0,
      guestPrice: (json['guestPrice'] ?? 0).toDouble(),
      memberPrice: (json['memberPrice'] ?? 0).toDouble(),
      pointsReward: json['pointsReward'] ?? 0,
      allowVouchers: json['allowVouchers'] ?? true,
      requirements: List<String>.from(json['requirements'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as DateTime? ?? DateTime.now()),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : (json['updatedAt'] as DateTime? ?? DateTime.now()),
      createdBy: json['createdBy'] ?? '',
    );
  }
  // === IDENTIFIERS & RELATIONSHIPS ===
  final String id;
  final String clubId; // Reference to club (for queries/security)
  final String facilityId; // Reference to facility

  // === DENORMALIZED DATA (for display without extra queries) ===
  final String clubName; // Club name for display
  final String facilityName; // Facility name for display

  // === ACTIVITY INFORMATION ===
  final String name; // Activity title
  final String description;
  final String category; // "Wellness", "Fitness", "Kids", "Workshops"
  final DateTime date;
  final String time; // Format "HH:mm"
  final int duration; // Duration in minutes
  final String timeCategory; // "Morning", "Afternoon", "Evening"

  // === CAPACITY ===
  final int capacity;
  final int bookedCount; // Current number of bookings

  // === DUAL PRICING (Guest vs Member) ===
  final double guestPrice;
  final double memberPrice;

  // === POINTS & REWARDS ===
  final int pointsReward;

  // === VOUCHER SETTINGS ===
  final bool allowVouchers; // Whether vouchers can be used for this activity

  final List<String> requirements;
  final String? imageUrl;

  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  // Computed property for spots left
  int get spotsLeft => capacity - bookedCount;

  // Calculate end time based on start time and duration
  DateTime get endTime {
    try {
      final timeParts = time.split(':');
      if (timeParts.length != 2) return date;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      return startDateTime.add(Duration(minutes: duration));
    } catch (e) {
      return date;
    }
  }

  // Format end time as HH:mm
  String get endTimeFormatted {
    final endDateTime = endTime;
    return '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
  }

  // Add this getter
  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    return _getDefaultImageForCategory(category);
  }

  String _getDefaultImageForCategory(String category) {
    switch (category) {
      case 'Wellness':
        return 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=300&h=200&fit=crop';
      case 'Fitness':
        return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=300&h=200&fit=crop';
      case 'Kids':
        return 'https://images.unsplash.com/photo-1566104827745-7237210ee915?w=300&h=200&fit=crop';
      case 'Workshops':
        return 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=300&h=200&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'facilityId': facilityId,
      'clubName': clubName,
      'facilityName': facilityName,
      'name': name,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'time': time,
      'duration': duration,
      'timeCategory': timeCategory,
      'capacity': capacity,
      'bookedCount': bookedCount,
      'guestPrice': guestPrice,
      'memberPrice': memberPrice,
      'pointsReward': pointsReward,
      'allowVouchers': allowVouchers,
      'requirements': requirements,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // CopyWith method for creating modified copies
  Activity copyWith({
    String? id,
    String? clubId,
    String? facilityId,
    String? clubName,
    String? facilityName,
    String? name,
    String? description,
    String? category,
    DateTime? date,
    String? time,
    int? duration,
    String? timeCategory,
    int? capacity,
    int? bookedCount,
    double? guestPrice,
    double? memberPrice,
    int? pointsReward,
    bool? allowVouchers,
    List<String>? requirements,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Activity(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      facilityId: facilityId ?? this.facilityId,
      clubName: clubName ?? this.clubName,
      facilityName: facilityName ?? this.facilityName,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      timeCategory: timeCategory ?? this.timeCategory,
      capacity: capacity ?? this.capacity,
      bookedCount: bookedCount ?? this.bookedCount,
      guestPrice: guestPrice ?? this.guestPrice,
      memberPrice: memberPrice ?? this.memberPrice,
      pointsReward: pointsReward ?? this.pointsReward,
      allowVouchers: allowVouchers ?? this.allowVouchers,
      requirements: requirements ?? this.requirements,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Helper to check if activity is in the past
  bool get isPast {
    try {
      final timeParts = time.split(':');
      if (timeParts.length != 2) return false;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final activityDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      return activityDateTime.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  // Helper to check if activity has available spots
  bool get hasAvailableSpots => spotsLeft > 0;

  // Helper to check if activity is almost full (less than 20% spots left)
  bool get isAlmostFull => spotsLeft > 0 && spotsLeft <= (capacity * 0.2);

  // Helper to check if activity is full
  bool get isFull => spotsLeft <= 0;

  // Helper method to determine time category from time string
  static String getTimeCategory(String time) {
    final hour = int.tryParse(time.split(':')[0]) ?? 12;
    if (hour >= 6 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 18) return 'Afternoon';
    return 'Evening';
  }
}
