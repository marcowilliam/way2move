import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
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
      duration: const Duration(milliseconds: 600),
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
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final goalsAsync = ref.watch(goalNotifierProvider);

    return Scaffold(
      key: AppKeys.goalListPage,
      appBar: AppBar(
        title: const Text('Goals'),
      ),
      floatingActionButton: FloatingActionButton(
        key: AppKeys.goalAddButton,
        onPressed: () => _showAddGoalDialog(context, uid),
        child: const Icon(Icons.add),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final delay = index * 0.08;
          final start = delay.clamp(0.0, 0.9);
          final end = (delay + 0.4).clamp(0.0, 1.0);
          final animation = CurvedAnimation(
            parent: staggerController,
            curve: Interval(start, end, curve: Curves.easeOut),
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
    final progress = goal.progressFraction;
    final statusColor = _statusColor(goal.status);

    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StatusBadge(status: goal.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _CategoryChip(category: goal.category),
                  if (goal.source == GoalSource.suggested) ...[
                    const SizedBox(width: 6),
                    _SourceChip(source: goal.source),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _ProgressBar(
                progress: progress,
                currentValue: goal.currentValue,
                targetValue: goal.targetValue,
                unit: goal.unit,
                statusColor: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(GoalStatus s) {
    switch (s) {
      case GoalStatus.active:
        return AppColors.primary;
      case GoalStatus.achieved:
        return AppColors.accentGreen;
      case GoalStatus.paused:
        return AppColors.textSecondary;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final GoalStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(category),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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

class _SourceChip extends StatelessWidget {
  final GoalSource source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    if (source != GoalSource.suggested) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Suggested',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final double currentValue;
  final double targetValue;
  final String unit;
  final Color statusColor;

  const _ProgressBar({
    required this.progress,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${currentValue.toStringAsFixed(currentValue.truncateToDouble() == currentValue ? 0 : 1)}'
              ' / '
              '${targetValue.toStringAsFixed(targetValue.truncateToDouble() == targetValue ? 0 : 1)}'
              ' $unit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyGoalsView extends StatelessWidget {
  const _EmptyGoalsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No goals yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete an assessment to get suggestions, or tap + to add a custom goal.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
