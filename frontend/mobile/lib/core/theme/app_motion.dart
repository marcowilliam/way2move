import 'package:flutter/widgets.dart';

/// Way2Move motion tokens (v1).
///
/// Source: docs/branding/brand-identity-plan.md §6.
/// Principle — "Breath, not bounce." Motion evokes calm movement: a chest
/// rising, a step landing, a settle. Nothing hyperactive. Snaps are rare.
/// Where Way2Fly springs with momentum, Way2Move arcs with intention.
abstract class WayMotion {
  // ── Duration tokens ──────────────────────────────────────────────────────
  /// Taps, card selection, nav tap — ~1/8 second.
  static const Duration micro = Duration(milliseconds: 120);

  /// Navigation, bottom sheet reveal, list insert.
  static const Duration standard = Duration(milliseconds: 280);

  /// Completion, summary, score reveal — long enough to feel final.
  static const Duration settled = Duration(milliseconds: 450);

  /// Reward moments — soft-gold shimmer on milestone completion.
  static const Duration reward = Duration(milliseconds: 680);

  /// Ambient breathing loop — journal mic listening state.
  static const Duration breath = Duration(milliseconds: 2400);

  // ── Curve tokens ─────────────────────────────────────────────────────────
  /// Micro-interactions — snappy but never harsh.
  static const Curve easeMicro = Curves.easeOut;

  /// Standard navigation/reveal — ease-out-quart approximation.
  static const Cubic easeStandard = Cubic(0.25, 1.0, 0.5, 1.0);

  /// Settled arrivals — slower tail, confident landing.
  static const Cubic easeSettled = Cubic(0.2, 0.9, 0.3, 1.0);

  /// Breathing — symmetric ease-in-out for repeating loops.
  static const Curve easeBreath = Curves.easeInOut;

  /// Reward moments — soft spring.
  static const Cubic easeReward = Cubic(0.34, 1.4, 0.64, 1.0);
}

/// Fade page transition at [WayMotion.standard] on [WayMotion.easeStandard].
Widget wayFadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: WayMotion.easeStandard),
    child: child,
  );
}

/// Slide-from-right page transition for pushed detail screens.
Widget waySlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: animation, curve: WayMotion.easeStandard)),
    child: child,
  );
}
