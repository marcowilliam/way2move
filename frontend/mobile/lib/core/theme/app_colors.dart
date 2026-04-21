import 'package:flutter/material.dart';

/// Way2Move brand palette (v1 — April 2026).
///
/// Source of truth: docs/branding/brand-identity-plan.md §3.
/// Terracotta primary + Sage accent + Soft Gold reward, on warm-linen /
/// warm-charcoal canvases. Sage is the "body awareness confirmation" color —
/// never used for CTAs.
abstract class AppColors {
  // ── Primary — Terracotta ─────────────────────────────────────────────────
  static const Color primary = Color(0xFFC4622D); // terracotta
  static const Color primaryDark = Color(0xFF9B4A1F); // burnt umber — pressed
  static const Color primaryLight = Color(0xFFE89062); // peach sand — hover

  // ── Accent — Sage (body awareness, not CTAs) ─────────────────────────────
  static const Color accent = Color(0xFF7A9B76); // sage
  static const Color accentLight = Color(0xFFC4D5BE); // mist sage — resolved

  // ── Reward — Soft Gold (milestones only, rare by design) ─────────────────
  static const Color reward = Color(0xFFD4A84B);

  // ── Surfaces — light ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAF6F0); // warm linen
  static const Color surface = Color(0xFFFFFDFA); // off-white (never pure)
  static const Color surfaceRaised = Color(0xFFF5EDE1); // cream — modals
  static const Color border = Color(0xFFEAE2D5); // fog
  static const Color divider = Color(0xFFEAE2D5);

  // ── Surfaces — dark ──────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF1A1612); // warm charcoal
  static const Color surfaceDark = Color(0xFF25201B); // espresso
  static const Color surfaceRaisedDark = Color(0xFF322A22); // warm slate
  static const Color borderDark = Color(0xFF3A322B); // smoke
  static const Color dividerDark = Color(0xFF3A322B);

  // ── Text — light ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F1815); // espresso ink
  static const Color textSecondary = Color(0xFF716660); // stone
  static const Color textDisabled = Color(0xFFB8ADA6); // soft stone
  static const Color textOnPrimary =
      Color(0xFFFFFDFA); // off-white on terracotta

  // ── Text — dark ──────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF5EFE7); // warm paper
  static const Color textSecondaryDark = Color(0xFFA89D94); // mushroom
  static const Color textDisabledDark = Color(0xFF5C524A);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBE4A3A); // clay red
  static const Color warning = Color(0xFFD99434); // honey
  static const Color info = Color(0xFF5A7A96); // dusk blue

  // ── Compensation severity ramp (brand-identity-plan.md §3.6) ────────────
  static const Color severityResolved = Color(0xFFC4D5BE); // mist sage
  static const Color severityImproving = Color(0xFF7A9B76); // sage
  static const Color severityMild = Color(0xFFD99434); // honey
  static const Color severityModerate = Color(0xFFC4622D); // terracotta
  static const Color severitySignificant = Color(0xFFBE4A3A); // clay red

  // ── Gait-phase (functional, not brand) ───────────────────────────────────
  static const Color gaitHeelStrike = Color(0xFF5A7A96);
  static const Color gaitMidStance = Color(0xFF7A9B76);
  static const Color gaitToeOff = Color(0xFFC4622D);
  static const Color gaitSwing = Color(0xFFD99434);

  // ─────────────────────────────────────────────────────────────────────────
  // Legacy name aliases — kept so existing screens compile unchanged during
  // the brand-v1 migration. Remove once every screen has migrated to the
  // semantic names above.
  // ─────────────────────────────────────────────────────────────────────────

  static const Color secondary = reward; // was warm gold
  static const Color secondaryLight = Color(0xFFE0C172);
  static const Color secondaryDark = Color(0xFFB0873A);

  static const Color accentGreen = accent; // "good" / completed — now sage
  static const Color accentRed = error;

  static const Color surfaceVariant = surfaceRaised;
  static const Color surfaceVariantDark = surfaceRaisedDark;

  static const Color sessionPlanned = info;
  static const Color sessionCompleted = accent;
  static const Color sessionSkipped = textSecondary;

  static const Color difficultyBeginner = accent;
  static const Color difficultyIntermediate = warning;
  static const Color difficultyAdvanced = error;
}
