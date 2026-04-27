import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/domain/entities/exercise.dart';
import '../../../exercises/presentation/providers/exercise_providers.dart';
import '../../../progression/domain/entities/progression_rule.dart';
import '../../../progression/domain/entities/progression_suggestion.dart';
import '../../../progression/domain/services/progression_service.dart';
import '../../../progression/presentation/providers/progression_providers.dart';
import '../../../progression/presentation/widgets/progression_suggestion_card.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/entities/sensation_feedback.dart';
import '../../domain/entities/session.dart';
import '../../domain/usecases/update_session.dart';
import '../providers/session_providers.dart';

class SessionSummaryPage extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionSummaryPage({super.key, required this.sessionId});

  @override
  ConsumerState<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends ConsumerState<SessionSummaryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebController;
  late Animation<double> _celebScale;
  late Animation<double> _fadeIn;

  // Progression suggestions computed from completed exercises
  final List<ProgressionSuggestion> _suggestions = [];
  final Set<String> _dismissedExerciseIds = {};

  @override
  void initState() {
    super.initState();
    _celebController = AnimationController(
      vsync: this,
      duration: WayMotion.settled + WayMotion.standard,
    );
    _celebScale = CurvedAnimation(
      parent: _celebController,
      curve: const Interval(0, 0.6, curve: WayMotion.easeSettled),
    );
    _fadeIn = CurvedAnimation(
      parent: _celebController,
      curve: const Interval(0.3, 1.0, curve: WayMotion.easeStandard),
    );
    _celebController.forward();
  }

  @override
  void dispose() {
    _celebController.dispose();
    super.dispose();
  }

  void _computeSuggestions(
      List<ExerciseBlock> completedBlocks, List<Exercise> exercises) {
    if (_suggestions.isNotEmpty) return; // already computed
    final service = ref.read(progressionServiceProvider);
    final rule = ref.read(globalProgressionRuleNotifierProvider).valueOrNull ??
        const ProgressionRule();

    for (final block in completedBlocks) {
      final exercise =
          exercises.where((e) => e.id == block.exerciseId).firstOrNull;
      if (exercise == null) continue;
      // Phase 1: use default wellness values (sleep=4.0, pulse=4.0, stomach=4.0)
      // Real wiring happens in Phase 4 when sleep/pulse data is available.
      final input = ProgressionInput(
        exerciseId: block.exerciseId,
        exerciseName: exercise.name,
        completedSessionCount: block.completedSetsCount,
        avgSleepQuality: 4.0,
        pulseScore: 4.0,
        avgStomachFeeling: 4.0,
        nextProgressionId: exercise.progressionIds.isNotEmpty
            ? exercise.progressionIds.first
            : null,
        rule: rule,
      );
      final results = service.evaluate(input);
      // Only show non-hold suggestions
      for (final s in results) {
        if (s.action != ProgressionAction.hold) {
          _suggestions.add(s);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(sessionHistoryProvider);
    final exercisesAsync = ref.watch(exerciseListProvider);

    return historyAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (sessions) {
        final session =
            sessions.where((s) => s.id == widget.sessionId).firstOrNull;
        final exercises = exercisesAsync.valueOrNull ?? [];

        if (session == null) {
          // Session not yet in history (latency) — show minimal summary
          return _buildSummaryScaffold(context, null, exercises);
        }

        return _buildSummaryScaffold(context, session, exercises);
      },
    );
  }

  Widget _buildSummaryScaffold(
      BuildContext context, Session? session, List<Exercise> exercises) {
    final theme = Theme.of(context);
    final completedBlocks =
        session?.exerciseBlocks.where((b) => b.isStarted).toList() ?? [];
    final totalSets =
        completedBlocks.fold<int>(0, (sum, b) => sum + b.completedSetsCount);

    // Compute suggestions lazily once exercises are available
    if (completedBlocks.isNotEmpty && exercises.isNotEmpty) {
      _computeSuggestions(completedBlocks, exercises);
    }

    return Scaffold(
      key: AppKeys.sessionSummaryPage,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _celebScale,
                      child: _SageCheckMark(animation: _celebScale),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Column(
                        children: [
                          Text(
                            'Workout Complete!',
                            style: theme.textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                          if (session?.focus != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              session!.focus!,
                              style: AppTypography.fraunces(
                                size: 18,
                                weight: FontWeight.w400,
                                color: theme.colorScheme.onSurfaceVariant,
                                style: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _StatsRow(
                        exercises: completedBlocks.length,
                        sets: totalSets,
                        duration: session?.durationMinutes,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (session?.notes?.isNotEmpty == true) ...[
                      FadeTransition(
                        opacity: _fadeIn,
                        child: _NotesCard(notes: session!.notes!),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (session != null) ...[
                      FadeTransition(
                        opacity: _fadeIn,
                        child: _SensationCard(session: session),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            ),
            if (session != null && completedBlocks.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final block = completedBlocks[index];
                      return FadeTransition(
                        opacity: _fadeIn,
                        child: _ExerciseSummaryTile(block: block),
                      );
                    },
                    childCount: completedBlocks.length,
                  ),
                ),
              ),
            if (_suggestions.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final suggestion = _suggestions[index];
                      if (_dismissedExerciseIds
                          .contains(suggestion.exerciseId)) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                        child: ProgressionSuggestionCard(
                          suggestion: suggestion,
                          onAccept: () {
                            setState(() {
                              _dismissedExerciseIds.add(suggestion.exerciseId);
                            });
                          },
                          onDismiss: () {
                            setState(() {
                              _dismissedExerciseIds.add(suggestion.exerciseId);
                            });
                          },
                        ),
                      );
                    },
                    childCount: _suggestions.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
          child: FilledButton(
            key: AppKeys.sessionDoneButton,
            onPressed: () => context.go(Routes.home),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text('Back to home'),
          ),
        ),
      ),
    );
  }
}

class _SageCheckMark extends StatelessWidget {
  final Animation<double> animation;
  const _SageCheckMark({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _CheckPainter(progress: animation.value),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 2,
      ringPaint,
    );

    final tickPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.36);

    final t = progress.clamp(0.0, 1.0);
    if (t < 0.5) {
      final pct = t / 0.5;
      canvas.drawLine(
        p1,
        Offset.lerp(p1, p2, pct)!,
        tickPaint,
      );
    } else {
      canvas.drawLine(p1, p2, tickPaint);
      final pct = (t - 0.5) / 0.5;
      canvas.drawLine(
        p2,
        Offset.lerp(p2, p3, pct)!,
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StatsRow extends StatelessWidget {
  final int exercises;
  final int sets;
  final int? duration;

  const _StatsRow({
    required this.exercises,
    required this.sets,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outline,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatColumn(label: 'exercises', value: '$exercises'),
        const SizedBox(width: AppSpacing.md),
        divider,
        const SizedBox(width: AppSpacing.md),
        _StatColumn(label: 'sets', value: '$sets'),
        const SizedBox(width: AppSpacing.md),
        divider,
        const SizedBox(width: AppSpacing.md),
        _StatColumn(
          label: 'duration',
          value: duration != null ? '${duration}m' : '—',
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.fraunces(
            size: 28,
            weight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(notes, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ExerciseSummaryTile extends ConsumerWidget {
  final ExerciseBlock block;
  const _ExerciseSummaryTile({required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exerciseListProvider);
    final exercise = exercisesAsync.maybeWhen(
      data: (list) => list.where((e) => e.id == block.exerciseId).firstOrNull,
      orElse: () => null,
    );

    final met = block.completedSetsCount >= block.plannedSets;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise?.name ?? block.category ?? block.exerciseId,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${block.completedSetsCount} sets done'
                  '${block.rpe != null ? ' · RPE ${block.rpe}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${block.plannedSets}→${block.completedSetsCount}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: met ? AppColors.accent : AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sensation feedback card (Sage tinted) ────────────────────────────────────

/// Body-listening capture: free-text "good areas" and "struggling areas",
/// 1-5 overall feel slider, free-text notes. Persists to the session via
/// `UpdateSession` use case.
///
/// Stays Sage — never CTA Terracotta — because Sage is the brand's
/// "your body is listening" colour.
class _SensationCard extends ConsumerStatefulWidget {
  final Session session;
  const _SensationCard({required this.session});

  @override
  ConsumerState<_SensationCard> createState() => _SensationCardState();
}

class _SensationCardState extends ConsumerState<_SensationCard> {
  late final TextEditingController _goodController;
  late final TextEditingController _strugglingController;
  late final TextEditingController _notesController;
  late List<String> _good;
  late List<String> _struggling;
  late int _overall;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.session.sensationFeedback;
    _good = List<String>.from(existing?.goodAreas ?? const []);
    _struggling = List<String>.from(existing?.strugglingAreas ?? const []);
    _overall = existing?.overallFeel ?? 3;
    _goodController = TextEditingController();
    _strugglingController = TextEditingController();
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _goodController.dispose();
    _strugglingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addGood() {
    final v = _goodController.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _good = [..._good, v];
      _goodController.clear();
      _saved = false;
    });
  }

  void _addStruggling() {
    final v = _strugglingController.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _struggling = [..._struggling, v];
      _strugglingController.clear();
      _saved = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final feedback = SensationFeedback(
        goodAreas: _good,
        strugglingAreas: _struggling,
        overallFeel: _overall,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      final updated = widget.session.copyWith(sensationFeedback: feedback);
      final useCase = UpdateSession(ref.read(sessionRepositoryProvider));
      final result = await useCase(updated);
      if (!mounted) return;
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save: $failure')),
          );
        },
        (_) {
          setState(() => _saved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sensation saved')),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('sensation_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite_outline,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'How did your body feel?',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Anywhere that felt good',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_good.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (var i = 0; i < _good.length; i++)
                    InputChip(
                      label: Text(_good[i]),
                      onDeleted: () => setState(() {
                        _good = List.of(_good)..removeAt(i);
                        _saved = false;
                      }),
                    ),
                ],
              ),
            ),
          TextField(
            key: const Key('sensation_good_input'),
            controller: _goodController,
            decoration: const InputDecoration(
              hintText: 'e.g. left glute, thoracic',
              isDense: true,
            ),
            onSubmitted: (_) => _addGood(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Anywhere that struggled',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_struggling.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (var i = 0; i < _struggling.length; i++)
                    InputChip(
                      label: Text(_struggling[i]),
                      onDeleted: () => setState(() {
                        _struggling = List.of(_struggling)..removeAt(i);
                        _saved = false;
                      }),
                    ),
                ],
              ),
            ),
          TextField(
            key: const Key('sensation_struggling_input'),
            controller: _strugglingController,
            decoration: const InputDecoration(
              hintText: 'e.g. neck gripping, right SI',
              isDense: true,
            ),
            onSubmitted: (_) => _addStruggling(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Overall feel',
            style: theme.textTheme.labelSmall,
          ),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    key: const Key('sensation_overall_slider'),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: _overall.toDouble(),
                    label: '$_overall',
                    onChanged: (v) => setState(() {
                      _overall = v.round();
                      _saved = false;
                    }),
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$_overall',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('sensation_notes_input'),
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Anything else worth remembering?',
              isDense: true,
            ),
            onChanged: (_) {
              if (_saved) setState(() => _saved = false);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('sensation_save_button'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Icon(
                      _saved ? Icons.check_circle : Icons.save_outlined,
                      color: AppColors.accent,
                      size: 18,
                    ),
              label: Text(
                _saved ? 'Saved' : 'Save sensation',
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
