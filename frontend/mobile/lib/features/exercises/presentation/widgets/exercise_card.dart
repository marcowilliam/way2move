import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DifficultyBadge(difficulty: exercise.difficulty),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                exercise.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (exercise.typeTags.isNotEmpty ||
                  exercise.regionTags.isNotEmpty) ...[
                const SizedBox(height: 10),
                _TagRow(exercise: exercise),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final ExerciseDifficulty difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (difficulty) {
      ExerciseDifficulty.beginner => ('Beginner', AppColors.difficultyBeginner),
      ExerciseDifficulty.intermediate => (
          'Intermediate',
          AppColors.difficultyIntermediate
        ),
      ExerciseDifficulty.advanced => ('Advanced', AppColors.difficultyAdvanced),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final Exercise exercise;
  const _TagRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final tags = [
      ...exercise.typeTags.map((t) => _tagLabel(t.name)),
      ...exercise.regionTags.map((t) => _tagLabel(t.name)),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.take(4).map((label) => _Chip(label: label)).toList(),
    );
  }

  String _tagLabel(String name) {
    // Convert camelCase to Title Case
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

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
