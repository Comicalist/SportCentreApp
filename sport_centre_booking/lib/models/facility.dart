/// Physical spaces where activities take place with capacity management
///
/// Represents venues like gyms, pools, courts, and studios owned by clubs.
/// Includes intelligent image fallbacks, capacity tracking, and time blocking
/// for maintenance or exclusive club use.
class Facility {
  const Facility({
    required this.id,
    required this.clubId,
    required this.title,
    required this.description,
    required this.maxCapacity,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.blockedTimes = const [],
  });

  /// Create Facility from JSON data with string-based date parsing
  factory Facility.fromJson(Map<String, dynamic> json, String id) {
    return Facility(
      id: id,
      clubId: json['clubId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      maxCapacity: json['maxCapacity'] as int,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      blockedTimes: List<Map<String, dynamic>>.from(json['blockedTimes'] ?? []),
    );
  }

  // Core identifiers
  final String id;
  final String clubId; // Owner club reference

  // Facility details
  final String title; // Display name (e.g., "Main Gym", "Pool Area")
  final String description; // Detailed facility description
  final int maxCapacity; // Maximum concurrent users
  final String? imageUrl; // Custom facility image
  final bool isActive; // Can be disabled for maintenance

  // Lifecycle tracking
  final DateTime createdAt;
  final DateTime updatedAt;

  // Time management
  final List<Map<String, dynamic>> blockedTimes; // Periods unavailable for booking

  /// Smart image fallbacks based on facility type detection
  /// Maps facility keywords to appropriate stock images
  static const Map<String, String> defaultImages = {
    'gym':
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=300&h=200&fit=crop',
    'pool':
        'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=300&h=200&fit=crop',
    'court':
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=300&h=200&fit=crop',
    'studio':
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
    'default':
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
  };

  /// Get image URL with intelligent fallback based on facility type
  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    return _getDefaultImageUrl();
  }

  /// Analyze facility title to determine appropriate default image
  String _getDefaultImageUrl() {
    final title = this.title.toLowerCase();
    if (title.contains('gym') || title.contains('weight')) {
      return defaultImages['gym']!;
    } else if (title.contains('pool') || title.contains('swim')) {
      return defaultImages['pool']!;
    } else if (title.contains('court') ||
        title.contains('tennis') ||
        title.contains('basketball') ||
        title.contains('badminton')) {
      return defaultImages['court']!;
    } else if (title.contains('studio') ||
        title.contains('yoga') ||
        title.contains('dance') ||
        title.contains('class')) {
      return defaultImages['studio']!;
    }
    return defaultImages['default']!;
  }

  /// Convert to JSON format (excludes ID for Firestore compatibility)
  Map<String, dynamic> toJson() {
    return {
      'clubId': clubId,
      'title': title,
      'description': description,
      'maxCapacity': maxCapacity,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'blockedTimes': blockedTimes,
    };
  }

  /// Create updated copy with modified fields (auto-updates timestamp)
  Facility copyWith({
    String? id,
    String? clubId,
    String? title,
    String? description,
    int? maxCapacity,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Map<String, dynamic>>? blockedTimes,
  }) {
    return Facility(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      title: title ?? this.title,
      description: description ?? this.description,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      blockedTimes: blockedTimes ?? this.blockedTimes,
    );
  }
}
