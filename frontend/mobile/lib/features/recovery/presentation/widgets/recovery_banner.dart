import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/recovery_score.dart';
import '../providers/recovery_providers.dart';

/// Compact card shown on the home dashboard.
/// Displays today's recovery score, zone colour, and recommendation headline.
/// Tapping navigates to RecoveryDetailPage.
class RecoveryBanner extends ConsumerStatefulWidget {
  const RecoveryBanner({super.key});

  @override
  ConsumerState<RecoveryBanner> createState() => _RecoveryBannerState();
}

class _RecoveryBannerState extends ConsumerState<RecoveryBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnim;
  double? _lastScore;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scoreAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateToScore(double score) {
    if (_lastScore == score) return;
    _lastScore = score;
    _scoreAnim = Tween<double>(begin: 0, end: score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(todayRecoveryScoreProvider);
    final recommendation = ref.watch(recoveryRecommendationProvider);

    return scoreAsync.when(
      loading: () => const _RecoveryBannerSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (score) {
        if (score == null) return const _NoRecoveryDataCard();

        _animateToScore(score.score);
        final zoneColor = _zoneColor(score.zone);

        return GestureDetector(
          onTap: () => context.push(Routes.recovery),
          child: AnimatedBuilder(
            animation: _scoreAnim,
            builder: (context, _) {
              return Card(
                clipBehavior: Clip.hardEdge,
                child: Container(
                  decoration: BoxDecoration(
                    color: zoneColor.withAlpha(20),
                    border: Border.all(color: zoneColor.withAlpha(77)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Score circle
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: zoneColor.withAlpha(38),
                            border: Border.all(color: zoneColor, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _scoreAnim.value.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: zoneColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Recovery Score',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  _ZoneChip(zone: score.zone),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recommendation?.headline ??
                                    score.recommendation,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
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

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.zone});
  final RecoveryZone zone;

  @override
  Widget build(BuildContext context) {
    final color = _zoneColor(zone);
    final label = zone.name[0].toUpperCase() + zone.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _RecoveryBannerSkeleton extends StatelessWidget {
  const _RecoveryBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 12, width: 100, color: AppColors.surfaceVariant),
                  const SizedBox(height: 6),
                  Container(
                      height: 12, width: 160, color: AppColors.surfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRecoveryDataCard extends StatelessWidget {
  const _NoRecoveryDataCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                ),
                child:
                    Icon(Icons.battery_unknown, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recovery Score',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                  const SizedBox(height: 4),
                  Text(
                    'No data yet — log sleep, sessions, and meals to see your score.',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
