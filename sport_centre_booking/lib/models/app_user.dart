import 'package:cloud_firestore/cloud_firestore.dart';

/// Core user authentication and profile model integrated with Firebase Auth/Firestore
///
/// This is the primary user entity that handles authentication, role management,
/// points system, and membership tracking. Used throughout the app for user
/// identification, permissions, and business logic.
class AppUser {
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
    this.isClubOwner = false,
  });

  /// Create AppUser from Firestore document with proper type conversions
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

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
      isClubOwner: data['isClubOwner'] ?? false,
    );
  }

  // Authentication identifiers
  final String uid; // Firebase Auth UID
  final String email;
  final String displayName;

  // Account lifecycle
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final bool isActive; // For account suspension

  // Role-based access control
  final String role; // 'user', 'admin'
  final bool isClubOwner; // Can create and manage clubs

  // Points and rewards system
  final int totalPoints; // All-time points earned
  final int availablePoints; // Current spendable points
  final int lifetimePointsEarned; // Historical tracking

  // Membership system
  final bool isMember; // Has active membership
  final String? membershipType; // 'basic', 'premium', 'vip'
  final DateTime? membershipExpiry;

  /// Convert to Firestore-compatible format with Timestamp objects
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'role': role,
      'isActive': isActive,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'lifetimePointsEarned': lifetimePointsEarned,
      'isMember': isMember,
      'membershipType': membershipType,
      'membershipExpiry': membershipExpiry != null
          ? Timestamp.fromDate(membershipExpiry!)
          : null,
      'isClubOwner': isClubOwner,
    };
  }

  /// Check if user has admin privileges
  bool get isAdmin => role == 'admin';

  /// Check if user can manage clubs (admin or club owner)
  bool get canManageClubs => isClubOwner || isAdmin;

  /// Extract first name from display name
  String get firstName {
    final parts = displayName.split(' ');
    return parts.isNotEmpty ? parts.first : displayName;
  }

  /// Generate initials for avatar display
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Create copy with updated fields
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
    bool? isClubOwner,
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
      isClubOwner: isClubOwner ?? this.isClubOwner,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, role: $role, isClubOwner: $isClubOwner)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
