import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../protocols/presentation/providers/active_protocols_provider.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_enums.dart';
import '../providers/workouts_provider.dart';

/// Workout Library — segmented filter (All / Ground Up / ABCDE / Snacks /
/// Bodybuilding / Themed) and a vertical list of workout cards. Tap a card
/// to drill into the detail view.
class WorkoutLibraryPage extends ConsumerStatefulWidget {
  const WorkoutLibraryPage({super.key});

  @override
  ConsumerState<WorkoutLibraryPage> createState() => _WorkoutLibraryPageState();
}

class _WorkoutLibraryPageState extends ConsumerState<WorkoutLibraryPage> {
  WorkoutKind? _selectedKind;
  bool _seeding = false;

  Future<void> _seedGroundUp() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _seeding = true);
    try {
      await ref.read(seedGroundUpProvider).call(
            userId: userId,
            startDate: DateTime.now(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From the Ground Up seeded')),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncWorkouts = ref.watch(workoutsProvider(_selectedKind));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('seed_ground_up_fab'),
        onPressed: _seeding ? null : _seedGroundUp,
        icon: _seeding
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.spa_outlined),
        label: const Text('Seed Ground Up'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              key: const Key('workout_kind_filter'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedKind == null,
                    onTap: () => setState(() => _selectedKind = null),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Ground Up',
                    selected: _selectedKind == WorkoutKind.fromGroundUp,
                    onTap: () => setState(
                        () => _selectedKind = WorkoutKind.fromGroundUp),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'ABCDE',
                    selected: _selectedKind == WorkoutKind.abcde,
                    onTap: () =>
                        setState(() => _selectedKind = WorkoutKind.abcde),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Snacks',
                    selected: _selectedKind == WorkoutKind.snack,
                    onTap: () =>
                        setState(() => _selectedKind = WorkoutKind.snack),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Bodybuilding',
                    selected: _selectedKind == WorkoutKind.bodybuilding,
                    onTap: () => setState(
                        () => _selectedKind = WorkoutKind.bodybuilding),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: 'Themed',
                    selected: _selectedKind == WorkoutKind.themed,
                    onTap: () =>
                        setState(() => _selectedKind = WorkoutKind.themed),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: asyncWorkouts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Could not load workouts: $e',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              data: (workouts) {
                if (workouts.isEmpty) {
                  return Center(
                    key: const Key('workout_library_empty'),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center_outlined,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No workouts yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Tap "Seed Ground Up" to load your physio prescription.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  key: const Key('workout_library_list'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xxl + AppSpacing.xxl,
                  ),
                  itemCount: workouts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) =>
                      _WorkoutCard(workout: workouts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? AppColors.textOnPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;

  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(Routes.workoutDetail(workout.id)),
        child: AnimatedContainer(
          duration: WayMotion.micro,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (workout.iconEmoji != null) ...[
                    Text(
                      workout.iconEmoji!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      workout.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  _KindChip(kind: workout.kind),
                ],
              ),
              if (workout.focus != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  workout.focus!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.activeBlocks.length} exercises',
                    style: theme.textTheme.labelSmall,
                  ),
                  if (workout.estimatedMinutes != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '~${workout.estimatedMinutes} min',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final WorkoutKind kind;

  const _KindChip({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (kind) {
      WorkoutKind.fromGroundUp => 'Ground Up',
      WorkoutKind.abcde => 'ABCDE',
      WorkoutKind.snack => 'Snack',
      WorkoutKind.bodybuilding => 'Bodybuilding',
      WorkoutKind.themed => 'Themed',
      WorkoutKind.recovery => 'Recovery',
      WorkoutKind.custom => 'Custom',
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
