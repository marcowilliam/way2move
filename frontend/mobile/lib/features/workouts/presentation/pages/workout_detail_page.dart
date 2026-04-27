import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../sessions/data/repositories/session_repository_impl.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../sessions/presentation/providers/session_providers.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_enums.dart';
import '../../domain/usecases/start_session_from_workout.dart';
import '../providers/workouts_provider.dart';

/// Workout Detail — header, blocks grouped by phase, "Start session" CTA.
class WorkoutDetailPage extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailPage({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends ConsumerState<WorkoutDetailPage> {
  bool _starting = false;

  Future<void> _startSession(Workout workout) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _starting = true);
    try {
      final useCase = StartSessionFromWorkout(
        ref.read(sessionRepositoryProvider),
      );
      final result = await useCase(
        workout: workout,
        userId: userId,
        date: DateTime.now(),
        slot: SessionSlot.flexible,
      );
      if (!mounted) return;
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start session: $failure')),
          );
        },
        (session) {
          ref
              .read(activeSessionProvider.notifier)
              .loadSession(session.copyWith(status: SessionStatus.inProgress));
          context.go(Routes.sessionActive);
        },
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncWorkout = ref.watch(workoutByIdProvider(widget.workoutId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: asyncWorkout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (workout) {
          if (workout == null) {
            return Center(
              child: Text(
                'Workout not found',
                style: theme.textTheme.titleMedium,
              ),
            );
          }
          final blocks = workout.activeBlocks
            ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          final byPhase = <ExercisePhase, List<ExerciseBlock>>{};
          for (final b in blocks) {
            final phase = b.phase ?? ExercisePhase.main;
            byPhase.putIfAbsent(phase, () => []).add(b);
          }
          final phaseOrder = [
            ExercisePhase.warmup,
            ExercisePhase.main,
            ExercisePhase.cooldown,
          ];

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg,
                ),
                children: [
                  Row(
                    children: [
                      if (workout.iconEmoji != null) ...[
                        Text(
                          workout.iconEmoji!,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          workout.name,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  if (workout.focus != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      workout.focus!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (workout.notes != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        workout.notes!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  for (final phase in phaseOrder)
                    if (byPhase[phase] != null &&
                        byPhase[phase]!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          _phaseLabel(phase),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      for (final block in byPhase[phase]!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _BlockCard(block: block),
                        ),
                    ],
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('start_session_button'),
                        onPressed:
                            _starting ? null : () => _startSession(workout),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                        child: _starting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textOnPrimary,
                                ),
                              )
                            : const Text('Start session'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _phaseLabel(ExercisePhase phase) => switch (phase) {
        ExercisePhase.warmup => 'WARM-UP',
        ExercisePhase.main => 'MAIN',
        ExercisePhase.cooldown => 'COOL-DOWN',
      };
}

class _BlockCard extends StatelessWidget {
  final ExerciseBlock block;

  const _BlockCard({required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cues = block.cuesOverride ?? const <String>[];
    final title = block.category ?? block.exerciseId;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (block.level != null) _LevelChip(level: block.level!),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${block.plannedSets} × ${block.plannedReps}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (block.directions != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              block.directions!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (cues.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final cue in cues)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        cue,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final ExerciseLevel level;

  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (level) {
      ExerciseLevel.access => 'Access',
      ExerciseLevel.foundation => 'Foundation',
      ExerciseLevel.strength => 'Strength',
      ExerciseLevel.integration => 'Integration',
      ExerciseLevel.supportSnack => 'Support',
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
