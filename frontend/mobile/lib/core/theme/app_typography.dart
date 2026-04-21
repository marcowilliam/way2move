import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Way2Move typography (v1).
///
/// Source: docs/branding/brand-identity-plan.md §4.
/// Fraunces (variable serif) is used for display styles — greetings, hero
/// numbers, journal moments. Manrope (humanist sans) is used for everything
/// else. JetBrains Mono is reserved for tabular data and voice timestamps.
///
/// The [build] helper returns a [TextTheme] parameterized by the primary and
/// secondary text colors, so the same scale can serve both light and dark
/// themes without duplication.
abstract class AppTypography {
  /// Display styles use Fraunces (serif).
  static TextStyle fraunces({
    required double size,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0,
    FontStyle? style,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      fontStyle: style,
      height: 1.1,
    );
  }

  /// UI and body styles use Manrope (humanist sans).
  static TextStyle manrope({
    required double size,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0,
    double height = 1.3,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Monospace used for weight/rep tables and voice-timestamp counters.
  static TextStyle mono({
    required double size,
    required FontWeight weight,
    required Color color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  /// Build the Material [TextTheme] for the given primary/secondary colors.
  static TextTheme build({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      // Display — Fraunces
      displayLarge: fraunces(
          size: 52,
          weight: FontWeight.w700,
          color: primary,
          letterSpacing: -1.0),
      displayMedium: fraunces(
          size: 40,
          weight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.5),
      displaySmall: fraunces(
          size: 32,
          weight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.3),

      // Headline — Manrope
      headlineLarge: manrope(
          size: 28,
          weight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.2),
      headlineMedium:
          manrope(size: 22, weight: FontWeight.w700, color: primary),
      headlineSmall: manrope(size: 18, weight: FontWeight.w700, color: primary),

      // Title — Manrope
      titleLarge: manrope(size: 17, weight: FontWeight.w600, color: primary),
      titleMedium: manrope(size: 15, weight: FontWeight.w600, color: primary),
      titleSmall: manrope(
          size: 13,
          weight: FontWeight.w600,
          color: primary,
          letterSpacing: 0.2),

      // Body — Manrope
      bodyLarge: manrope(
          size: 16, weight: FontWeight.w400, color: primary, height: 1.45),
      bodyMedium: manrope(
          size: 14, weight: FontWeight.w400, color: secondary, height: 1.45),
      bodySmall: manrope(
          size: 12, weight: FontWeight.w400, color: secondary, height: 1.45),

      // Label — Manrope (tracked for small uppercase-ish labels)
      labelLarge: manrope(
          size: 13,
          weight: FontWeight.w600,
          color: primary,
          letterSpacing: 0.4),
      labelMedium: manrope(
          size: 11,
          weight: FontWeight.w600,
          color: secondary,
          letterSpacing: 0.6),
      labelSmall: manrope(
          size: 10,
          weight: FontWeight.w600,
          color: secondary,
          letterSpacing: 0.8),
    );
  }
}
