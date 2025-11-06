import 'package:cloud_firestore/cloud_firestore.dart';

/// Sports club entity with approval workflow and time blocking system
///
/// Represents a sports club that owns facilities and offers activities.
/// Includes admin approval process and ability to block time slots for
/// club-exclusive use (training sessions, maintenance, etc.)
class Club {
  Club({
    required this.id,
    required this.name,
    required this.ownerId,
    this.location,
    this.isActive = true,
    this.isApproved = false,
    required this.createdAt,
    this.blockedTimes = const [],
  });

  /// Create Club from Firestore document with safe date conversion
  factory Club.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Club(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      location: data['location'],
      isActive: data['isActive'] ?? true,
      isApproved: data['isApproved'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      blockedTimes: List<Map<String, dynamic>>.from(data['blockedTimes'] ?? []),
    );
  }

  // Core identifiers
  final String id;
  final String name; // Club display name
  final String ownerId; // User who created/manages this club

  // Club details
  final String? location; // Physical address or description
  final DateTime createdAt;

  // Admin controls
  final bool isActive; // Club can be disabled by admin
  final bool isApproved; // Requires admin approval before activities can be created

  // Time management system
  final List<Map<String, dynamic>> blockedTimes; // Periods unavailable for public booking

  /// Create updated copy with new values
  Club copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? location,
    bool? isActive,
    bool? isApproved,
    DateTime? createdAt,
    List<Map<String, dynamic>>? blockedTimes,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      blockedTimes: blockedTimes ?? this.blockedTimes,
    );
  }

  /// Convert to Firestore format (excludes ID as it's stored as document ID)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'location': location,
      'isActive': isActive,
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
      'blockedTimes': blockedTimes,
    };
  }
}
