class Activity {
  final String id;
  final String name;
  final String description;
  final String category;
  final DateTime date;
  final String time;
  final String location;
  final double price;
  final int pointsReward;
  final int capacity;
  final int spotsLeft;
  final String imageUrl;
  final List<String> requirements;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    required this.price,
    required this.pointsReward,
    required this.capacity,
    required this.spotsLeft,
    required this.imageUrl,
    this.requirements = const [],
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      location: json['location'],
      price: json['price'].toDouble(),
      pointsReward: json['pointsReward'],
      capacity: json['capacity'],
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
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'price': price,
      'pointsReward': pointsReward,
      'capacity': capacity,
      'spotsLeft': spotsLeft,
      'imageUrl': imageUrl,
      'requirements': requirements,
    };
  }
}