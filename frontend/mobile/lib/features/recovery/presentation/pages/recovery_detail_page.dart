import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/recovery_score.dart';
import '../providers/recovery_providers.dart';

class RecoveryDetailPage extends ConsumerStatefulWidget {
  const RecoveryDetailPage({super.key});

  @override
  ConsumerState<RecoveryDetailPage> createState() => _RecoveryDetailPageState();
}

class _RecoveryDetailPageState extends ConsumerState<RecoveryDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnim;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  double? _lastScore;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _animateRingTo(double score) {
    if (_lastScore == score) return;
    _lastScore = score;
    _ringAnim = Tween<double>(begin: 0, end: score / 100.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );
    _ringController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(todayRecoveryScoreProvider);
    final trend = ref.watch(recoveryTrendProvider);
    final recommendation = ref.watch(recoveryRecommendationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: scoreAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Could not load recovery score.')),
          data: (score) {
            if (score == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No recovery data yet.\nLog sleep, training sessions, weekly pulse, and meals to generate your score.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            _animateRingTo(score.score);
            final zoneColor = _zoneColor(score.zone);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Score ring
                  Center(
                    child: AnimatedBuilder(
                      animation: _ringAnim,
                      builder: (context, _) {
                        return _ScoreRing(
                          progress: _ringAnim.value,
                          score: score.score,
                          zone: score.zone,
                          color: zoneColor,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recommendation card
                  if (recommendation != null) ...[
                    _RecommendationCard(
                      recommendation: recommendation,
                      zoneColor: zoneColor,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Component breakdown
                  Text('Score Breakdown',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _ComponentRow(
                    label: 'Sleep Quality',
                    icon: Icons.bedtime_outlined,
                    value: score.components.sleepComponent,
                    weight: '30%',
                  ),
                  const SizedBox(height: 8),
                  _ComponentRow(
                    label: 'Training Load',
                    icon: Icons.fitness_center_outlined,
                    value: score.components.trainingLoadComponent,
                    weight: '40%',
                  ),
                  const SizedBox(height: 8),
                  _ComponentRow(
                    label: 'Weekly Pulse',
                    icon: Icons.favorite_outline,
                    value: score.components.weeklyPulseComponent,
                    weight: '20%',
                  ),
                  const SizedBox(height: 8),
                  _ComponentRow(
                    label: 'Gut Feeling',
                    icon: Icons.restaurant_outlined,
                    value: score.components.gutFeelingComponent,
                    weight: '10%',
                  ),
                  const SizedBox(height: 24),

                  // 7-day trend sparkline
                  Text('7-Day Trend',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  trend.when(
                    loading: () => const SizedBox(
                        height: 80,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (scores) => _TrendSparkline(scores: scores),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Score Ring ────────────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.progress,
    required this.score,
    required this.zone,
    required this.color,
  });
  final double progress;
  final double score;
  final RecoveryZone zone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final zoneLabel = zone.name[0].toUpperCase() + zone.name.substring(1);
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                zoneLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const strokeWidth = 12.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withAlpha(38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at top
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Recommendation Card ───────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.zoneColor,
  });
  final dynamic recommendation;
  final Color zoneColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zoneColor.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zoneColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.headline as String,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: zoneColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.detail as String,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ── Component Row ─────────────────────────────────────────────────────────────

class _ComponentRow extends StatefulWidget {
  const _ComponentRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.weight,
  });
  final String label;
  final IconData icon;
  final double value;
  final String weight;

  @override
  State<_ComponentRow> createState() => _ComponentRowState();
}

class _ComponentRowState extends State<_ComponentRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.value / 100.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _barColor(widget.value);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.label,
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                Text(
                  widget.weight,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _anim.value,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _barColor(double value) {
    if (value >= 75) return AppColors.accentGreen;
    if (value >= 50) return AppColors.secondary;
    return AppColors.accentRed;
  }
}

// ── Trend Sparkline ───────────────────────────────────────────────────────────

class _TrendSparkline extends StatelessWidget {
  const _TrendSparkline({required this.scores});
  final List<RecoveryScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Not enough data yet.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 80,
          child: CustomPaint(
            painter:
                _SparklinePainter(scores: scores.map((s) => s.score).toList()),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> scores;

  const _SparklinePainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final n = scores.length;
    final points = List.generate(n, (i) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      final y = size.height - (scores[i] / 100.0) * size.height;
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);

    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.scores != scores;
}

Color _zoneColor(RecoveryZone zone) {
  switch (zone) {
    case RecoveryZone.green:
      return AppColors.accentGreen;
    case RecoveryZone.yellow:
      return AppColors.secondary;
    case RecoveryZone.red:
      return AppColors.accentRed;
  }
}
