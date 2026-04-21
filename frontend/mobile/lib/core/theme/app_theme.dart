import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Way2Move theme (v1 — April 2026).
///
/// Source: docs/branding/brand-identity-plan.md §10.
/// Terracotta primary on warm-linen (light) or warm-charcoal (dark) canvases.
/// Radii and spacing are softer than Way2Fly. Sage is reserved for body-
/// awareness confirmation — never used for primary buttons.
abstract class AppTheme {
  static ThemeData get light => _build(_LightTokens());
  static ThemeData get dark => _build(_DarkTokens());

  static ThemeData _build(_ThemeTokens t) {
    final textTheme = AppTypography.build(
      primary: t.textPrimary,
      secondary: t.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      scaffoldBackgroundColor: t.background,
      cardColor: t.surface,
      dividerColor: t.divider,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primary.withValues(alpha: 0.12),
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.accent,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.accent.withValues(alpha: 0.12),
        onSecondaryContainer: AppColors.accent,
        tertiary: AppColors.reward,
        onTertiary: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        surface: t.surface,
        onSurface: t.textPrimary,
        surfaceContainerHighest: t.surfaceRaised,
        onSurfaceVariant: t.textSecondary,
        outline: t.border,
        outlineVariant: t.divider,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: IconThemeData(color: t.textPrimary, size: 24),
      ),

      // ── Inputs: underline-only (no filled bg), terracotta on focus ───────
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: t.textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: t.textDisabled),
        floatingLabelStyle:
            textTheme.bodySmall?.copyWith(color: AppColors.primary),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor:
              AppColors.textOnPrimary.withValues(alpha: 0.8),
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          textStyle:
              textTheme.titleMedium?.copyWith(color: AppColors.textOnPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          textStyle:
              textTheme.titleMedium?.copyWith(color: AppColors.textOnPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          textStyle: textTheme.titleMedium,
          side: BorderSide(color: t.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.titleMedium,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: t.border),
        ),
      ),

      // ── Bottom nav (5 tabs, no FAB — quieter than Way2Fly) ───────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: t.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            textTheme.labelMedium?.copyWith(color: AppColors.primary),
        unselectedLabelStyle: textTheme.labelMedium,
      ),

      // ── Chips (outlined, sage-accented for body-awareness tags) ──────────
      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        disabledColor: t.surfaceRaised,
        labelStyle: textTheme.labelLarge?.copyWith(color: t.textPrimary),
        secondaryLabelStyle:
            textTheme.labelLarge?.copyWith(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          side: BorderSide(color: t.border),
        ),
        side: BorderSide(color: t.border),
      ),

      // ── FAB (rare — Way2Move avoids them where possible) ─────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // ── Dialogs & bottom sheets (28px radius) ────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: t.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: DividerThemeData(color: t.divider, thickness: 1, space: 0),
    );
  }
}

/// Theme-variant tokens (light vs dark). Extracted so [AppTheme._build] can
/// consume a single shape regardless of mode.
abstract class _ThemeTokens {
  Brightness get brightness;
  Color get background;
  Color get surface;
  Color get surfaceRaised;
  Color get border;
  Color get divider;
  Color get textPrimary;
  Color get textSecondary;
  Color get textDisabled;
}

class _LightTokens implements _ThemeTokens {
  @override
  Brightness get brightness => Brightness.light;
  @override
  Color get background => AppColors.background;
  @override
  Color get surface => AppColors.surface;
  @override
  Color get surfaceRaised => AppColors.surfaceRaised;
  @override
  Color get border => AppColors.border;
  @override
  Color get divider => AppColors.divider;
  @override
  Color get textPrimary => AppColors.textPrimary;
  @override
  Color get textSecondary => AppColors.textSecondary;
  @override
  Color get textDisabled => AppColors.textDisabled;
}

class _DarkTokens implements _ThemeTokens {
  @override
  Brightness get brightness => Brightness.dark;
  @override
  Color get background => AppColors.backgroundDark;
  @override
  Color get surface => AppColors.surfaceDark;
  @override
  Color get surfaceRaised => AppColors.surfaceRaisedDark;
  @override
  Color get border => AppColors.borderDark;
  @override
  Color get divider => AppColors.dividerDark;
  @override
  Color get textPrimary => AppColors.textPrimaryDark;
  @override
  Color get textSecondary => AppColors.textSecondaryDark;
  @override
  Color get textDisabled => AppColors.textDisabledDark;
}
