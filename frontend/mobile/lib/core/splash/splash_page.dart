import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../shared/widgets/way2move_logo_mark.dart';

/// First-paint screen shown while auth / profile state is loading. Matches
/// mockup §1: stacked logo fades in (280ms), wordmark slides in (200ms
/// delay), mark pulses once softly (680ms reward curve) before the router
/// transitions away.
///
/// This widget owns only the visual; the router decides when to leave it.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;

  late final Animation<double> _markOpacity;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _markScale;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: WayMotion.reward,
    );

    // Mark fades in 0–280ms.
    _markOpacity = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.31, curve: WayMotion.easeStandard),
    );

    // Wordmark fades + slides in 200–500ms.
    _wordmarkOpacity = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.22, 0.56, curve: WayMotion.easeStandard),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_wordmarkOpacity);

    // Soft pulse — 1.0 → 1.04 → 1.0 over 680ms.
    _markScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _pulseController, curve: WayMotion.easeReward),
    );

    _fadeController.forward().whenComplete(() {
      if (mounted) _pulseController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markColor = isDark ? AppColors.textPrimaryDark : AppColors.primary;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_markOpacity, _markScale]),
                builder: (_, __) => Opacity(
                  opacity: _markOpacity.value,
                  child: Transform.scale(
                    scale: _markScale.value,
                    child: Way2MoveLogoMark(size: 128, color: markColor),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SlideTransition(
                position: _wordmarkSlide,
                child: FadeTransition(
                  opacity: _wordmarkOpacity,
                  child: _Wordmark(textColor: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.textColor});
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('WAY',
            style: AppTypography.manrope(
              size: 32,
              weight: FontWeight.w800,
              color: textColor,
              letterSpacing: -1.2,
            )),
        Text('2',
            style: AppTypography.manrope(
              size: 32,
              weight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -1.2,
            )),
        Text('MOVE',
            style: AppTypography.manrope(
              size: 32,
              weight: FontWeight.w800,
              color: textColor,
              letterSpacing: -1.2,
            )),
      ],
    );
  }
}
