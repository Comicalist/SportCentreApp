import 'package:flutter/material.dart';

/// UI utility functions for consistent activity presentation and user experience
class ActivityHelpers {
  /// Returns brand-consistent colors for activity categorization and filtering
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

  /// Provides intuitive icons matching activity category for visual recognition
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

  /// Color-codes availability status for quick booking decision making
  static Color getSpotsColor(int spotsLeft) {
    if (spotsLeft <= 0) return Colors.red[700]!;
    if (spotsLeft <= 1) return Colors.red;
    if (spotsLeft <= 3) return Colors.orange;
    return Colors.green;
  }

  /// Calculates responsive card dimensions for optimal grid layout display
  static double calculateCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 40.0;
    const gridSpacing = 16.0;
    return (screenWidth - horizontalPadding - gridSpacing) / 2;
  }
}
