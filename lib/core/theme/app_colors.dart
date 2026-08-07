import 'package:flutter/material.dart';

/// Central colour palette for the app. Light, clean and calm.
class AppColors {
  AppColors._();

  // Surfaces — a whisper of mint in the background makes white cards float.
  static const Color background = Color(0xFFF4F9F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEFF5F2);

  // Brand
  static const Color primary = Color(0xFF2ED3B7); // mint / health
  static const Color primaryDark = Color(0xFF1FB49B);
  static const Color primarySoft = Color(0xFFE4F8F4);
  static const Color primaryContainer = Color(0xFFCBF2EA);

  // Semantic accents
  static const Color weight = Color(0xFF4E7CFF); // weight blue
  static const Color weightSoft = Color(0xFFE8EEFF);
  static const Color calorie = Color(0xFFFF7A5A); // calorie coral
  static const Color calorieSoft = Color(0xFFFFEDE7);
  static const Color bodyFat = Color(0xFF9B6DFF); // body-fat purple
  static const Color bodyFatSoft = Color(0xFFF1EAFF);
  static const Color success = Color(0xFF34C77B);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFF5455C);

  // Text
  static const Color textPrimary = Color(0xFF1A1D1F);
  static const Color textSecondary = Color(0xFF6F767E);
  static const Color textTertiary = Color(0xFF9A9FA5);

  // Lines
  static const Color border = Color(0xFFE9EDF1);
  static const Color divider = Color(0xFFEFF2F5);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF3EE0C4),
    Color(0xFF1FB49B),
  ];
  static const List<Color> weightGradient = [
    Color(0xFF6E96FF),
    Color(0xFF4E7CFF),
  ];
  static const List<Color> calorieGradient = [
    Color(0xFFFF9C7E),
    Color(0xFFFF7A5A),
  ];
  static const List<Color> bodyFatGradient = [
    Color(0xFFB48DFF),
    Color(0xFF9B6DFF),
  ];
}
