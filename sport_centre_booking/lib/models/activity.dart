class Activity {
  final String id;
  final String name;
  final String description;
  final String category;
  final String club;
  final DateTime date;
  final String time;
  final String timeCategory; // morning, afternoon, evening
  final String location;
  final double price; // Default guest price for backward compatibility
  final double guestPrice;
  final double memberPrice;
  final int pointsReward;
  final int capacity;
  final int bookedCount; // New field for tracking bookings
  final int spotsLeft;
  final String imageUrl;
  final List<String> requirements;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.club,
    required this.date,
    required this.time,
    required this.timeCategory,
    required this.location,
    required this.price,
    double? guestPrice,
    double? memberPrice,
    required this.pointsReward,
    required this.capacity,
    this.bookedCount = 0, // Default to 0 bookings
    required this.spotsLeft,
    required this.imageUrl,
    this.requirements = const [],
  }) : guestPrice = guestPrice ?? price,
       memberPrice = memberPrice ?? (price * 0.8); // 20% discount for members

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      club: json['club'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      timeCategory: json['timeCategory'],
      location: json['location'],
      price: json['price'].toDouble(),
      guestPrice: json['guestPrice']?.toDouble(),
      memberPrice: json['memberPrice']?.toDouble(),
      pointsReward: json['pointsReward'],
      capacity: json['capacity'],
      bookedCount: json['bookedCount'] ?? 0, // Default to 0 if not present
      spotsLeft: json['spotsLeft'],
      imageUrl: json['imageUrl'],
      requirements: List<String>.from(json['requirements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'club': club,
      'date': date.toIso8601String(),
      'time': time,
      'timeCategory': timeCategory,
      'location': location,
      'price': price,
      'guestPrice': guestPrice,
      'memberPrice': memberPrice,
      'pointsReward': pointsReward,
      'capacity': capacity,
      'bookedCount': bookedCount,
      'spotsLeft': spotsLeft,
      'imageUrl': imageUrl,
      'requirements': requirements,
    };
  }

  // Helper method to determine time category from time string
  static String getTimeCategory(String time) {
    final hour = int.tryParse(time.split(':')[0]) ?? 12;
    if (hour >= 6 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 18) return 'Afternoon';
    return 'Evening';
  }
}