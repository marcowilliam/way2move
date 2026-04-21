/// Way2Move spacing & radius tokens (v1).
///
/// Source: docs/branding/brand-identity-plan.md §7.
/// Base unit is 4px. Radii are softer than Way2Fly's scale — warmer curves
/// suit the brand. Cards use [radiusMd], hero cards use [radiusLg], modals
/// and bottom sheets use [radiusXl].
abstract class AppSpacing {
  // ── Spacing scale (4/8/16/24/32/48) ──────────────────────────────────────
  static const double xs = 4; // icon-to-label gap
  static const double sm = 8; // tight pad
  static const double md = 16; // default pad / card pad
  static const double lg = 24; // section spacing
  static const double xl = 32; // major section break
  static const double xxl = 48; // screen-level breathing room

  // ── Radii (10/14/20/28) ──────────────────────────────────────────────────
  static const double radiusSm = 10; // chips, inputs, pills
  static const double radiusMd = 14; // cards
  static const double radiusLg = 20; // hero cards, focal surfaces
  static const double radiusXl = 28; // modals, bottom sheets

  // ── Tap target ───────────────────────────────────────────────────────────
  static const double minTapTarget = 48;
}
