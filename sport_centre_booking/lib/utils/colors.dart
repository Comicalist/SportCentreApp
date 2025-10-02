import 'package:flutter/material.dart';

/// Application color constants
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary colors
  static const Color primary = Color(0xFF009688); // Teal
  static const Color primaryDark = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF4DB6AC);

  // Secondary colors
  static const Color secondary = Color(0xFFFF9800); // Orange for points/rewards
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFFCC02);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF212121);
  static const Color onSurface = Color(0xFF757575);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Category colors
  static const Color wellnessCategory = Color(0xFF8BC34A);
  static const Color fitnessCategory = Color(0xFF2196F3);
  static const Color kidsCategory = Color(0xFFFF5722);
  static const Color workshopCategory = Color(0xFF9C27B0);

  // Booking status colors
  static const Color confirmedStatus = primary;
  static const Color completedStatus = success;
  static const Color cancelledStatus = error;
  static const Color waitlistStatus = warning;
}