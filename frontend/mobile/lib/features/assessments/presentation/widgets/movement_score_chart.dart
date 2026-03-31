import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:way2move/features/assessments/domain/entities/assessment_comparison_result.dart';
import 'package:way2move/features/assessments/domain/entities/video_analysis.dart';

/// A grouped bar chart comparing movement scores between two assessments.
///
/// Each screening movement gets two side-by-side bars:
/// - Muted color: initial assessment score
/// - Accent color: re-assessment score
///
/// Bars animate on load using [AnimationController].
class MovementScoreChart extends StatefulWidget {
  final AssessmentComparisonResult comparison;

  /// Color for the initial-assessment bars.
  final Color initialColor;

  /// Color for the re-assessment bars.
  final Color reAssessmentColor;

  const MovementScoreChart({
    super.key,
    required this.comparison,
    this.initialColor = const Color(0xFFB0BEC5),
    this.reAssessmentColor = const Color(0xFF26A69A),
  });

  @override
  State<MovementScoreChart> createState() => _MovementScoreChartState();
}

class _MovementScoreChartState extends State<MovementScoreChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const movements = ScreeningMovement.values;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend(theme),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: movements.map((movement) {
                  return Expanded(
                    child: _MovementBarGroup(
                      movement: movement,
                      initialScore:
                          widget.comparison.initial.movementScore(movement),
                      reAssessmentScore: widget.comparison.reAssessment
                          .movementScore(movement),
                      initialColor: widget.initialColor,
                      reAssessmentColor: widget.reAssessmentColor,
                      progress: _animation.value,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      children: [
        _LegendDot(color: widget.initialColor),
        const SizedBox(width: 6),
        Text('Initial', style: theme.textTheme.bodySmall),
        const SizedBox(width: 16),
        _LegendDot(color: widget.reAssessmentColor),
        const SizedBox(width: 6),
        Text('Re-Assessment', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MovementBarGroup extends StatelessWidget {
  final ScreeningMovement movement;
  final double? initialScore;
  final double? reAssessmentScore;
  final Color initialColor;
  final Color reAssessmentColor;
  final double progress;

  static const _maxBarHeight = 160.0;
  static const _barWidth = 10.0;

  const _MovementBarGroup({
    required this.movement,
    required this.initialScore,
    required this.reAssessmentScore,
    required this.initialColor,
    required this.reAssessmentColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initH = (initialScore ?? 0) / 100.0 * _maxBarHeight * progress;
    final reH = (reAssessmentScore ?? 0) / 100.0 * _maxBarHeight * progress;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(initH, initialColor),
            const SizedBox(width: 3),
            _bar(reH, reAssessmentColor),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _shortLabel(movement),
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: _barWidth,
      height: math.max(height, 2.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }

  String _shortLabel(ScreeningMovement m) => switch (m) {
        ScreeningMovement.overheadSquat => 'OH\nSquat',
        ScreeningMovement.singleLegStance => 'SL\nStance',
        ScreeningMovement.forwardBend => 'Fwd\nBend',
        ScreeningMovement.shoulderRaise => 'Shld\nRaise',
        ScreeningMovement.walkingGait => 'Gait',
      };
}
