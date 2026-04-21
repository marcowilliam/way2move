import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs + 2,
        AppSpacing.md,
        AppSpacing.xs + 2,
      ),
      child: Hero(
        tag: 'exercise-${exercise.id}',
        flightShuttleBuilder: (_, __, ___, ____, _____) =>
            _HeroShuttle(exercise: exercise),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RegionIcon(
                          regions: exercise.regionTags,
                          difficulty: exercise.difficulty),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _DifficultyDot(difficulty: exercise.difficulty),
                    ],
                  ),
                  if (exercise.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      exercise.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (exercise.typeTags.isNotEmpty ||
                      exercise.regionTags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm + 2),
                    _TagRow(exercise: exercise),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroShuttle extends StatelessWidget {
  final Exercise exercise;
  const _HeroShuttle({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: Container());
  }
}

class _RegionIcon extends StatelessWidget {
  final List<BodyRegion> regions;
  final ExerciseDifficulty difficulty;
  const _RegionIcon({required this.regions, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(regions);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(icon, size: 18, color: AppColors.accent),
    );
  }

  IconData _iconFor(List<BodyRegion> regions) {
    if (regions.isEmpty) return Icons.self_improvement;
    switch (regions.first) {
      case BodyRegion.neck:
        return Icons.face;
      case BodyRegion.shoulder:
        return Icons.open_with;
      case BodyRegion.thoracic:
      case BodyRegion.lumbar:
        return Icons.straighten;
      case BodyRegion.hip:
        return Icons.accessibility_new;
      case BodyRegion.core:
        return Icons.adjust;
      case BodyRegion.knee:
        return Icons.directions_walk;
      case BodyRegion.ankle:
        return Icons.hiking;
      case BodyRegion.fullBody:
        return Icons.accessibility;
    }
  }
}

class _DifficultyDot extends StatelessWidget {
  final ExerciseDifficulty difficulty;
  const _DifficultyDot({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      ExerciseDifficulty.beginner => AppColors.accent,
      ExerciseDifficulty.intermediate => AppColors.warning,
      ExerciseDifficulty.advanced => AppColors.primary,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _TagRow extends StatelessWidget {
  final Exercise exercise;
  const _TagRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final tags = [
      ...exercise.typeTags.map((t) => _humanize(t.name)),
      ...exercise.regionTags.map((t) => _humanize(t.name)),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: tags.take(3).map((label) => _TagPill(label: label)).toList(),
    );
  }

  String _humanize(String name) {
    final result = StringBuffer();
    for (var i = 0; i < name.length; i++) {
      if (i > 0 && name[i] == name[i].toUpperCase()) {
        result.write(' ');
      }
      result.write(i == 0 ? name[i].toUpperCase() : name[i]);
    }
    return result.toString();
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
