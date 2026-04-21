import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
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
      duration: WayMotion.settled,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: WayMotion.easeSettled);
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'exercise-${exercise.id}',
                  child: Container(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    child: Center(
                      child: Icon(
                        exercise.videoUrl.isNotEmpty
                            ? Icons.play_circle_outline
                            : Icons.self_improvement,
                        size: 64,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TagRow(exercise: exercise),
                    if (exercise.regionTags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: exercise.regionTags
                            .map((r) => _RegionChip(label: _humanize(r.name)))
                            .toList(),
                      ),
                    ],
                    if (exercise.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        exercise.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                    if (exercise.cues.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _CollapsibleSection(
                        title: 'Coaching cues',
                        initiallyExpanded: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < exercise.cues.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                          '${i + 1}',
                                          style: const TextStyle(
                                            color: AppColors.textOnPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm + 4),
                                    Expanded(
                                      child: Text(
                                        exercise.cues[i],
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (exercise.progressionIds.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _CollapsibleSection(
                        title: 'Progressions',
                        child: _RelatedList(
                          exerciseIds: exercise.progressionIds,
                          accent: AppColors.primary,
                        ),
                      ),
                    ],
                    if (exercise.regressionIds.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _CollapsibleSection(
                        title: 'Regressions',
                        child: _RelatedList(
                          exerciseIds: exercise.regressionIds,
                          accent: AppColors.accent,
                        ),
                      ),
                    ],
                    if (exercise.equipmentTags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Equipment',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: exercise.equipmentTags
                            .map((t) =>
                                _RegionChip(label: _humanize(t.name)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add to session'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ),
      ),
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

class _TagRow extends StatelessWidget {
  final Exercise exercise;
  const _TagRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _DifficultyPill(difficulty: exercise.difficulty),
        ...exercise.typeTags.take(3).map((t) => _OutlinePill(
              label: _humanize(t.name),
              color: AppColors.accent,
            )),
      ],
    );
  }

  static String _humanize(String name) {
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

class _DifficultyPill extends StatelessWidget {
  final ExerciseDifficulty difficulty;
  const _DifficultyPill({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (difficulty) {
      ExerciseDifficulty.beginner => ('Beginner', AppColors.accent),
      ExerciseDifficulty.intermediate => ('Intermediate', AppColors.warning),
      ExerciseDifficulty.advanced => ('Advanced', AppColors.primary),
    };
    return _OutlinePill(label: label, color: color);
  }
}

class _OutlinePill extends StatelessWidget {
  final String label;
  final Color color;
  const _OutlinePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  const _RegionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: theme.textTheme.titleMedium),
                  ),
                  AnimatedRotation(
                    duration: WayMotion.micro,
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: WayMotion.standard,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

class _RelatedList extends ConsumerWidget {
  final List<String> exerciseIds;
  final Color accent;

  const _RelatedList({required this.exerciseIds, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exerciseIds.map((id) {
        final exAsync = ref.watch(exerciseDetailProvider(id));
        return exAsync.when(
          data: (ex) => ex == null
              ? const SizedBox.shrink()
              : InkWell(
                  onTap: () => context.push(Routes.exerciseDetail(id)),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(Icons.self_improvement, size: 18, color: accent),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: Text(ex.name, style: theme.textTheme.bodyMedium),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
      }).toList(),
    );
  }
}
