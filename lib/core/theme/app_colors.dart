import 'package:flutter/material.dart';

class AppColors {
  // --- Light Mode ---

  // 60% Base Colors
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);

  // 30% Primary Color (Dark Blue)
  static const Color primary = Color(0xFF0F408F);
  static const Color primaryLight = Color(0xFFE3EFFF);
  static const Color primaryDark = Color(0xFF1727B5);

  // 10% Accent Color (Vibrant Turquoise)
  static const Color accent = Color(0xFF00C9BD);
  static const Color accentLight = Color(0xFF7FFFF8);
  static const Color accentHover = Color(0xFF00B3A8);

  // Complementary
  static const Color blueSecondary = Color(0xFF179BE6);
  static const Color purple = Color(0xFF9052E0);
  static const Color orange = Color(0xFFEC9A3A);
  static const Color coral = Color(0xFFE05252);

  // Functional (Semantic)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFEC9A3A);
  static const Color error = Color(0xFFE05252);
  static const Color info = Color(0xFF179BE6);

  // Text (Light Mode)
  static const Color textPrimary = Color(0xFF0E1A2B);
  static const Color textSecondary = Color(0xFF64748B);

  // --- Dark Mode ---

  static const Color darkBackground = Color(0xFF0A0F1A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkPrimary = Color(
    0xFF00C9BD,
  ); // Turquoise becomes primary in dark mode
  static const Color darkAccent = Color(0xFF179BE6); // Blue becomes accent
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}
