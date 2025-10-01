import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  // Time categories for filtering
  static const List<String> timeCategories = [
    'Morning',
    'Afternoon', 
    'Evening',
  ];

  // UI Constants
  static const double cardBorderRadius = 16.0;
  static const double categoryBadgeRadius = 20.0;
  static const double filterBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  
  // Spacing
  static const double defaultPadding = 20.0;
  static const double cardPadding = 8.0;
  static const double gridSpacing = 16.0;
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 16.0;

  // Image
  static const double activityImageHeight = 120.0;
  static const double categoryIconSize = 60.0;
  
  // Shadow
  static const double shadowBlurRadius = 10.0;
  static const Offset shadowOffset = Offset(0, 2);
  static const double shadowOpacity = 0.08;
}

/// Category color mappings
class CategoryColors {
  static const Map<String, Color> colors = {
    'Wellness': Colors.teal,
    'Fitness': Colors.orange,
    'Kids': Colors.purple,
    'Workshops': Colors.blue,
  };

  static Color getColor(String category) {
    return colors[category] ?? Colors.grey;
  }
}

/// Category icon mappings  
class CategoryIcons {
  static const Map<String, IconData> icons = {
    'Wellness': Icons.self_improvement,
    'Fitness': Icons.fitness_center,
    'Kids': Icons.child_care,
    'Workshops': Icons.school,
  };

  static IconData getIcon(String category) {
    return icons[category] ?? Icons.event;
  }
}