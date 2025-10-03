import 'package:flutter/material.dart';

/// Helper functions for activity-related UI logic
class ActivityHelpers {
  /// Get color for activity category
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Wellness':
        return Colors.teal;
      case 'Fitness':
        return Colors.orange;
      case 'Kids':
        return Colors.purple;
      case 'Workshops':
        return Colors.blue;
      default:
        return Colors.grey[600]!;
    }
  }

  /// Get icon for activity category
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Wellness':
        return Icons.self_improvement;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Kids':
        return Icons.child_care;
      case 'Workshops':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  /// Get color for spots availability
  static Color getSpotsColor(int spotsLeft) {
    if (spotsLeft <= 0) return Colors.red[700]!; // Darker red for sold out
    if (spotsLeft <= 1) return Colors.red;
    if (spotsLeft <= 3) return Colors.orange;
    return Colors.green;
  }

  /// Calculate card width for grid layout
  static double calculateCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 40.0; // 20px on each side
    const gridSpacing = 16.0;
    return (screenWidth - horizontalPadding - gridSpacing) / 2;
  }
}