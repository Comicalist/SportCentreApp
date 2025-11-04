
/// Represents a sport activity offered by a club at a specific facility
/// 
/// Activities can be booked by both club members and guests, with different
/// pricing tiers. Each activity has a capacity limit and tracks bookings.
class Activity {
  const Activity({
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
      duration: json['duration'] ?? 60,
      timeCategory: json['timeCategory'] ?? getTimeCategory(json['time'] ?? '00:00'),
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

  // Core identifiers
  final String id;
  final String clubId;
  final String facilityId;

  // Display information (denormalized for performance)
  final String clubName;
  final String facilityName;

  // Activity details
  final String name;
  final String description;
  final String category; // "Wellness", "Fitness", "Kids", "Workshops"
  final DateTime date;
  final String time; // Format "HH:mm"
  final int duration; // Duration in minutes
  final String timeCategory; // "Morning", "Afternoon", "Evening"

  // Capacity management
  final int capacity;
  final int bookedCount;

  // Pricing (dual tier for members vs guests)
  final double guestPrice;
  final double memberPrice;

  // Rewards and requirements
  final int pointsReward;
  final bool allowVouchers;
  final List<String> requirements;

  // Media and metadata
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  /// Available spots remaining for booking
  int get spotsLeft => capacity - bookedCount;

  /// Calculate activity end time based on start time and duration
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

  /// Format end time as HH:mm string
  String get endTimeFormatted {
    final endDateTime = endTime;
    return '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get display-ready image URL with fallback to category defaults
  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    return _getDefaultImageForCategory(category);
  }

  /// Default images for activity categories
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

  /// Check if activity is in the past
  bool get isPast {
    try {
      final timeParts = time.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      
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

  /// Check if activity has available spots
  bool get hasAvailableSpots => spotsLeft > 0;

  /// Check if activity is almost full (less than 20% spots left)
  bool get isAlmostFull => spotsLeft > 0 && spotsLeft <= (capacity * 0.2);

  /// Check if activity is completely booked
  bool get isFull => spotsLeft <= 0;

  /// Determine time category from time string
  static String getTimeCategory(String time) {
    final hour = int.tryParse(time.split(':')[0]) ?? 12;
    if (hour >= 6 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 18) return 'Afternoon';
    return 'Evening';
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
}
