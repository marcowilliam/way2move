import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_providers.dart';
import '../widgets/add_goal_dialog.dart';

class GoalListPage extends ConsumerStatefulWidget {
  const GoalListPage({super.key});

  @override
  ConsumerState<GoalListPage> createState() => _GoalListPageState();
}

class _GoalListPageState extends ConsumerState<GoalListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: WayMotion.reward,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final goalsAsync = ref.watch(goalNotifierProvider);

    return Scaffold(
      key: AppKeys.goalListPage,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Goals',
          style: theme.textTheme.displaySmall,
        ),
        centerTitle: false,
        toolbarHeight: 72,
        actions: [
          IconButton(
            key: AppKeys.goalAddButton,
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(context, uid),
            tooltip: 'Add goal',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) => _GoalListBody(
          goals: goals,
          staggerController: _staggerController,
          onRefresh: () async => ref.invalidate(goalNotifierProvider),
          onGoalTap: (goal) => context.push(Routes.goalDetail(goal.id)),
        ),
      ),
    );
  }

  Future<void> _showAddGoalDialog(BuildContext context, String userId) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AddGoalDialog(userId: userId),
    );
  }
}

class _GoalListBody extends StatelessWidget {
  final List<Goal> goals;
  final AnimationController staggerController;
  final Future<void> Function() onRefresh;
  final void Function(Goal) onGoalTap;

  const _GoalListBody({
    required this.goals,
    required this.staggerController,
    required this.onRefresh,
    required this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const _EmptyGoalsView();
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          100,
        ),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final delay = index * 0.08;
          final start = delay.clamp(0.0, 0.9);
          final end = (delay + 0.4).clamp(0.0, 1.0);
          final animation = CurvedAnimation(
            parent: staggerController,
            curve: Interval(start, end, curve: WayMotion.easeStandard),
          );
          return _AnimatedGoalCard(
            goal: goals[index],
            animation: animation,
            onTap: () => onGoalTap(goals[index]),
          );
        },
      ),
    );
  }
}

class _AnimatedGoalCard extends StatelessWidget {
  final Goal goal;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _AnimatedGoalCard({
    required this.goal,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: _GoalCard(goal: goal, onTap: onTap),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;

  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.progressFraction;
    final ringColor = _statusColor(goal.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _ProgressRing(progress: progress, color: ringColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTypography.manrope(
                          size: 17,
                          weight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Wrap(
                        spacing: AppSpacing.xs + 2,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _CategoryChip(category: goal.category),
                          if (goal.origin == GoalOrigin.suggested)
                            _OriginChip(origin: goal.origin),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_format(goal.currentValue)} / ${_format(goal.targetValue)} ${goal.unit}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: goal.status, color: ringColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _format(double v) {
    return v.truncateToDouble() == v
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
  }

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

class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  const _ProgressRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0.0, 1.0), color: color),
        child: Center(
          child: Text(
            '${(progress * 100).round()}%',
            style: AppTypography.fraunces(
              size: 13,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final bg = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -3.14159 / 2, progress * 3.14159 * 2, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _StatusBadge extends StatelessWidget {
  final GoalStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    if (status == GoalStatus.active) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
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
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Text(
        _label(category),
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  String _label(GoalCategory c) {
    switch (c) {
      case GoalCategory.mobility:
        return 'Mobility';
      case GoalCategory.stability:
        return 'Stability';
      case GoalCategory.strength:
        return 'Strength';
      case GoalCategory.endurance:
        return 'Endurance';
      case GoalCategory.posture:
        return 'Posture';
      case GoalCategory.sport:
        return 'Sport';
      case GoalCategory.recovery:
        return 'Recovery';
      case GoalCategory.general:
        return 'General';
    }
  }
}

class _OriginChip extends StatelessWidget {
  final GoalOrigin origin;
  const _OriginChip({required this.origin});

  @override
  Widget build(BuildContext context) {
    if (origin != GoalOrigin.suggested) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.reward.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: const Text(
        'Suggested',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.reward,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EmptyGoalsView extends StatelessWidget {
  const _EmptyGoalsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_outlined,
                size: 44,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No goals yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete an assessment to get suggestions, or tap + to add a custom goal.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
