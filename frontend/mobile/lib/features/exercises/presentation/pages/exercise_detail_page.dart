import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exercise.dart';
import '../providers/exercise_providers.dart';

class ExerciseDetailPage extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailPage({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseDetailProvider(exerciseId));

    return exerciseAsync.when(
      data: (exercise) => exercise == null
          ? const _NotFoundScaffold()
          : _ExerciseDetailView(exercise: exercise),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _NotFoundScaffold(),
    );
  }
}

class _NotFoundScaffold extends StatelessWidget {
  const _NotFoundScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Exercise not found')),
    );
  }
}

class _ExerciseDetailView extends StatefulWidget {
  final Exercise exercise;
  const _ExerciseDetailView({required this.exercise});

  @override
  State<_ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<_ExerciseDetailView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.exerciseDetailPage,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: exercise.videoUrl.isNotEmpty ? 220 : 0,
              pinned: true,
              title: Hero(
                tag: 'exercise_name_${exercise.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    exercise.name,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              flexibleSpace: exercise.videoUrl.isNotEmpty
                  ? FlexibleSpaceBar(
                      background: Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _DifficultyBadge(difficulty: exercise.difficulty),
                        ...exercise.typeTags.take(3).map((t) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _TagChip(label: t.name),
                            )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Description', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(exercise.description,
                        style: theme.textTheme.bodyLarge),
                    if (exercise.cues.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Coaching Cues', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ...exercise.cues.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                    if (exercise.equipmentTags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Equipment', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: exercise.equipmentTags
                            .map((t) => _TagChip(label: t.name))
                            .toList(),
                      ),
                    ],
                    if (exercise.regionTags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Body Regions', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: exercise.regionTags
                            .map((t) => _TagChip(label: t.name))
                            .toList(),
                      ),
                    ],
                    if (exercise.progressionIds.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _RelatedSection(
                        title: 'Progressions',
                        icon: Icons.arrow_upward,
                        color: AppColors.accentGreen,
                        exerciseIds: exercise.progressionIds,
                      ),
                    ],
                    if (exercise.regressionIds.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _RelatedSection(
                        title: 'Regressions',
                        icon: Icons.arrow_downward,
                        color: AppColors.secondary,
                        exerciseIds: exercise.regressionIds,
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
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

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RelatedSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> exerciseIds;

  const _RelatedSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.exerciseIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        ...exerciseIds.map((id) {
          final exAsync = ref.watch(exerciseDetailProvider(id));
          return exAsync.when(
            data: (ex) => ex == null
                ? const SizedBox.shrink()
                : InkWell(
                    onTap: () => context.push(Routes.exerciseDetail(id)),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center_outlined,
                              size: 18, color: color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(ex.name,
                                style: theme.textTheme.bodyMedium),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
            loading: () => const SizedBox(
              height: 36,
              child: Center(child: LinearProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          );
        }),
      ],
    );
  }
}
