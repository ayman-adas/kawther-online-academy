import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Professional Blue
  static const Color primary = Color(0xFF1565C0); // Blue 800
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);

  // Secondary Palette - Accent
  static const Color accent = Color(0xFFFFA000); // Amber 700

  // Backgrounds
  static const Color background = Color(0xFFF5F7FA); // Soft Grey-Blue
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);

  // Modern UI Extras
  static const List<Color> primaryGradient = [primary, primaryLight];
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}
