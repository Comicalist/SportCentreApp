import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;
  final String name;
  final String ownerId;
  final String? location;
  final bool isActive;
  final bool isApproved;
  final DateTime createdAt;
  final List<Map<String, dynamic>> blockedTimes;

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

  factory Club.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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