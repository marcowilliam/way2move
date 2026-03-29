import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand — muted earth tones
  static const Color primary = Color(0xFF4A7C59); // sage green
  static const Color primaryLight = Color(0xFF6FA882);
  static const Color primaryDark = Color(0xFF2D5A3D);

  static const Color secondary = Color(0xFFB8860B); // warm gold
  static const Color secondaryLight = Color(0xFFD4A822);
  static const Color secondaryDark = Color(0xFF8A6408);

  // Accent — progress & achievements
  static const Color accent = Color(0xFFE67E22); // energetic orange
  static const Color accentGreen = Color(0xFF27AE60); // completion green
  static const Color accentRed = Color(0xFFE74C3C); // error/warning

  // Neutrals — light mode
  static const Color background = Color(0xFFF8F6F2); // warm off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0EDE8);
  static const Color border = Color(0xFFE0DDD8);
  static const Color divider = Color(0xFFECEAE5);

  // Text — light mode
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Neutrals — dark mode
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);
  static const Color borderDark = Color(0xFF3A3A3A);
  static const Color dividerDark = Color(0xFF2E2E2E);

  // Text — dark mode
  static const Color textPrimaryDark = Color(0xFFF0EFEA);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);

  // Session status colors
  static const Color sessionPlanned = Color(0xFF3498DB);
  static const Color sessionCompleted = Color(0xFF27AE60);
  static const Color sessionSkipped = Color(0xFF95A5A6);

  // Difficulty colors
  static const Color difficultyBeginner = Color(0xFF27AE60);
  static const Color difficultyIntermediate = Color(0xFFE67E22);
  static const Color difficultyAdvanced = Color(0xFFE74C3C);
}
