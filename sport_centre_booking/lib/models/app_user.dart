import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for the application
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String role;
  final bool isActive;
  final int totalPoints;
  final int availablePoints;
  final int lifetimePointsEarned;
  final bool isMember;
  final String? membershipType; // 'basic', 'premium', 'vip'
  final DateTime? membershipExpiry;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.createdAt,
    this.lastLoginAt,
    this.role = 'user',
    this.isActive = true,
    this.totalPoints = 0,
    this.availablePoints = 0,
    this.lifetimePointsEarned = 0,
    this.isMember = false,
    this.membershipType,
    this.membershipExpiry,
  });

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,
      totalPoints: data['totalPoints'] ?? 0,
      availablePoints: data['availablePoints'] ?? 0,
      lifetimePointsEarned: data['lifetimePointsEarned'] ?? 0,
      isMember: data['isMember'] ?? false,
      membershipType: data['membershipType'],
      membershipExpiry: (data['membershipExpiry'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert AppUser to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'role': role,
      'isActive': isActive,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'lifetimePointsEarned': lifetimePointsEarned,
      'isMember': isMember,
      'membershipType': membershipType,
      'membershipExpiry': membershipExpiry != null ? Timestamp.fromDate(membershipExpiry!) : null,
    };
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Get user's first name
  String get firstName {
    final parts = displayName.split(' ');
    return parts.isNotEmpty ? parts.first : displayName;
  }

  /// Get user's initials for avatar
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Create a copy of AppUser with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? role,
    bool? isActive,
    int? totalPoints,
    int? availablePoints,
    int? lifetimePointsEarned,
    bool? isMember,
    String? membershipType,
    DateTime? membershipExpiry,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      totalPoints: totalPoints ?? this.totalPoints,
      availablePoints: availablePoints ?? this.availablePoints,
      lifetimePointsEarned: lifetimePointsEarned ?? this.lifetimePointsEarned,
      isMember: isMember ?? this.isMember,
      membershipType: membershipType ?? this.membershipType,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}