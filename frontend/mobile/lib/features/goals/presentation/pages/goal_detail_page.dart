import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_providers.dart';

class GoalDetailPage extends ConsumerStatefulWidget {
  final String goalId;
  const GoalDetailPage({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends ConsumerState<GoalDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  bool _achieveAnimating = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: WayMotion.settled,
    );
    _fadeIn =
        CurvedAnimation(parent: _entryController, curve: WayMotion.easeSettled);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryController, curve: WayMotion.easeSettled));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalNotifierProvider);

    return goalsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (goals) {
        final goal = goals.cast<Goal?>().firstWhere(
              (g) => g?.id == widget.goalId,
              orElse: () => null,
            );

        if (goal == null) {
          return const Scaffold(
            body: Center(child: Text('Goal not found')),
          );
        }

        final theme = Theme.of(context);
        return Scaffold(
          key: AppKeys.goalDetailPage,
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              goal.name,
              style: theme.textTheme.titleLarge,
            ),
          ),
          body: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideIn,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _GoalProgressHero(goal: goal),
                  const SizedBox(height: AppSpacing.xl),
                  if (goal.description.isNotEmpty) ...[
                    Text(
                      goal.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (goal.compensationIds.isNotEmpty) ...[
                    const _SectionTitle(label: 'Linked compensations'),
                    _LinkedChipRow(
                      ids: goal.compensationIds,
                      color: AppColors.severityModerate,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (goal.exerciseIds.isNotEmpty) ...[
                    const _SectionTitle(label: 'Linked exercises'),
                    Column(
                      children: goal.exerciseIds
                          .map((id) => _LinkedExerciseTile(id: id))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (goal.achievedAt != null) ...[
                    _AchievementCard(achievedAt: goal.achievedAt!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (goal.status != GoalStatus.achieved)
                    FilledButton.icon(
                      key: AppKeys.goalMarkAchievedButton,
                      onPressed: _achieveAnimating
                          ? null
                          : () => _markAchieved(context, goal),
                      icon: _achieveAnimating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as achieved'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAchieved(BuildContext context, Goal goal) async {
    setState(() => _achieveAnimating = true);
    final result =
        await ref.read(goalNotifierProvider.notifier).markAchieved(goal.id);
    if (!mounted) return;
    setState(() => _achieveAnimating = false);
    result.fold(
      (_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to update goal'))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.textOnPrimary),
              SizedBox(width: AppSpacing.sm),
              Text('Goal achieved!'),
            ],
          ),
          backgroundColor: AppColors.accent,
        ),
      ),
    );
  }
}

class _GoalProgressHero extends StatelessWidget {
  final Goal goal;
  const _GoalProgressHero({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.progressFraction;
    final statusColor = _statusColor(goal.status);

    return Column(
      children: [
        Row(
          children: [
            _CategoryChip(category: goal.category),
            const Spacer(),
            _StatusBadge(status: goal.status, color: statusColor),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _HeroRingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: statusColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: AppTypography.fraunces(
                      size: 52,
                      weight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Text(
                    'complete',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          goal.targetMetric,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_format(goal.currentValue)} → ${_format(goal.targetValue)} ${goal.unit}',
          style: AppTypography.fraunces(
            size: 20,
            weight: FontWeight.w400,
            color: theme.colorScheme.onSurface,
            style: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _format(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Color _statusColor(GoalStatus s) {
    switch (s) {
      case GoalStatus.active:
        return AppColors.primary;
      case GoalStatus.achieved:
        return AppColors.accent;
      case GoalStatus.paused:
        return AppColors.textSecondary;
    }
  }
}

class _HeroRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _HeroRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bg = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -3.14159 / 2, progress * 3.14159 * 2, false, fg);
  }

  @override
  bool shouldRepaint(covariant _HeroRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _StatusBadge extends StatelessWidget {
  final GoalStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        _label(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _label(GoalStatus s) {
    switch (s) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.achieved:
        return 'Achieved';
      case GoalStatus.paused:
        return 'Paused';
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final GoalCategory category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Text(
        category.name[0].toUpperCase() + category.name.substring(1),
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _LinkedChipRow extends StatelessWidget {
  final List<String> ids;
  final Color color;
  const _LinkedChipRow({required this.ids, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs + 2,
      children: ids
          .map(
            (id) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                id,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LinkedExerciseTile extends StatelessWidget {
  final String id;
  const _LinkedExerciseTile({required this.id});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.self_improvement, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(id, style: theme.textTheme.bodyMedium),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final DateTime achievedAt;
  const _AchievementCard({required this.achievedAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.reward.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.reward.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.reward, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal achieved',
                  style: AppTypography.fraunces(
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppColors.reward,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(achievedAt),
                  style: AppTypography.fraunces(
                    size: 14,
                    weight: FontWeight.w400,
                    color: AppColors.reward,
                    style: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) => '${dt.day} ${_month(dt.month)} ${dt.year}';

String _month(int m) => const [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][m];
