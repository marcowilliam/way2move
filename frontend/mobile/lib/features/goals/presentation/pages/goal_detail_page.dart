import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
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
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
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

        return Scaffold(
          key: AppKeys.goalDetailPage,
          appBar: AppBar(
            title: Text(goal.name),
          ),
          body: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideIn,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _GoalProgressCard(goal: goal),
                  const SizedBox(height: 16),
                  if (goal.description.isNotEmpty) ...[
                    const _SectionTitle(label: 'Description'),
                    Card(
                      elevation: 0,
                      color: AppColors.surfaceVariant,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          goal.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (goal.compensationIds.isNotEmpty) ...[
                    const _SectionTitle(label: 'Linked Compensations'),
                    _ChipRow(
                      ids: goal.compensationIds,
                      color: AppColors.accentRed,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (goal.exerciseIds.isNotEmpty) ...[
                    const _SectionTitle(label: 'Linked Exercises'),
                    _ChipRow(
                      ids: goal.exerciseIds,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (goal.achievedAt != null) ...[
                    const _SectionTitle(label: 'Achievement'),
                    Card(
                      elevation: 0,
                      color: AppColors.accentGreen.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.accentGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: AppColors.accentGreen),
                        title: const Text('Goal achieved!',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentGreen)),
                        subtitle: Text(_formatDate(goal.achievedAt!)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (goal.status != GoalStatus.achieved) ...[
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
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Achieved'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
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
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Goal achieved!'),
            ],
          ),
          backgroundColor: AppColors.accentGreen,
        ),
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final Goal goal;
  const _GoalProgressCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressFraction;
    final statusColor = _statusColor(goal.status);

    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(status: goal.status, color: statusColor),
                const Spacer(),
                _CategoryChip(category: goal.category),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              goal.targetMetric,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  goal.currentValue.toStringAsFixed(
                      goal.currentValue.truncateToDouble() == goal.currentValue
                          ? 0
                          : 1),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                ),
                Text(
                  ' / ${goal.targetValue.toStringAsFixed(goal.targetValue.truncateToDouble() == goal.targetValue ? 0 : 1)} ${goal.unit}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% complete',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
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
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        category.name[0].toUpperCase() + category.name.substring(1),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> ids;
  final Color color;
  const _ChipRow({required this.ids, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ids
          .map(
            (id) => Chip(
              label: Text(
                id,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                    ),
              ),
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
          .toList(),
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
