class UserProfile {
  final String id;
  final String name;
  final String email;
  final int totalPoints;
  final List<String> bookingHistory;
  final List<String> upcomingBookings;
  final String profileImageUrl;
  final DateTime joinDate;
  final String role;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.totalPoints,
    required this.bookingHistory,
    required this.upcomingBookings,
    this.profileImageUrl = '',
    required this.joinDate,
    this.role = 'user'
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      totalPoints: json['totalPoints'],
      bookingHistory: List<String>.from(json['bookingHistory'] ?? []),
      upcomingBookings: List<String>.from(json['upcomingBookings'] ?? []),
      profileImageUrl: json['profileImageUrl'] ?? '',
      joinDate: DateTime.parse(json['joinDate']),
      role: json['role'] ?? 'user',
    );
  }

  // Checker for Admin
  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'totalPoints': totalPoints,
      'bookingHistory': bookingHistory,
      'upcomingBookings': upcomingBookings,
      'profileImageUrl': profileImageUrl,
      'joinDate': joinDate.toIso8601String(),
      'role' : role,
    };
  }
}