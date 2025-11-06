import 'package:flutter/material.dart';

/// Design system constants ensuring consistent user experience across the app
class AppConstants {
  // Activity scheduling filters for user convenience
  static const List<String> timeCategories = [
    'Morning',
    'Afternoon',
    'Evening',
  ];

  // Border radius values for cohesive visual design
  static const double cardBorderRadius = 16.0;
  static const double categoryBadgeRadius = 20.0;
  static const double filterBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;

  // Standardized spacing for layout consistency and readability
  static const double defaultPadding = 20.0;
  static const double cardPadding = 8.0;
  static const double gridSpacing = 16.0;
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 16.0;

  // Image dimensions optimized for activity presentation
  static const double activityImageHeight = 120.0;
  static const double categoryIconSize = 60.0;

  // Subtle shadow effects for depth perception and modern UI
  static const double shadowBlurRadius = 10.0;
  static const Offset shadowOffset = Offset(0, 2);
  static const double shadowOpacity = 0.08;
}

/// Activity category visual identification system
class CategoryColors {
  static const Map<String, Color> colors = {
    'Wellness': Colors.teal,
    'Fitness': Colors.orange,
    'Kids': Colors.purple,
    'Workshops': Colors.blue,
  };

  /// Returns category-specific color for consistent branding
  static Color getColor(String category) {
    return colors[category] ?? Colors.grey;
  }
}

/// Intuitive iconography for immediate activity type recognition
class CategoryIcons {
  static const Map<String, IconData> icons = {
    'Wellness': Icons.self_improvement,
    'Fitness': Icons.fitness_center,
    'Kids': Icons.child_care,
    'Workshops': Icons.school,
  };

  /// Returns category-appropriate icon for visual clarity
  static IconData getIcon(String category) {
    return icons[category] ?? Icons.event;
  }
}
