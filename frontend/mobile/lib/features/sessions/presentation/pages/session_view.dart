import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/presentation/providers/exercise_providers.dart';
import '../../domain/entities/session.dart';
import '../providers/session_providers.dart';

class SessionView extends ConsumerStatefulWidget {
  const SessionView({super.key});

  @override
  ConsumerState<SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends ConsumerState<SessionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: WayMotion.settled,
    )..forward();
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: WayMotion.easeSettled,
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeSessionProvider);

    return activeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (state) {
        if (state == null) {
          return const Scaffold(
            body: Center(child: Text('No active session')),
          );
        }
        return _buildWorkout(context, state);
      },
    );
  }

  Widget _buildWorkout(BuildContext context, ActiveSessionState state) {
    final session = state.session;
    final theme = Theme.of(context);

    final currentIndex = session.exerciseBlocks.indexWhere(
      (b) => !b.isStarted || b.completedSetsCount < b.plannedSets,
    );

    return Scaffold(
      key: AppKeys.sessionView,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _confirmExit(context),
            ),
            actions: [
              _ProgressChip(session: session),
              const SizedBox(width: AppSpacing.md),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.focus ?? 'Workout',
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDate(session.date),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final block = session.exerciseBlocks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                    child: _ExerciseBlockCard(
                      block: block,
                      index: index,
                      isCurrent: index == currentIndex,
                    ),
                  );
                },
                childCount: session.exerciseBlocks.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(state: state),
    );
  }

  String _formatDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
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
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit workout?'),
        content: const Text('Your progress will be lost if you leave now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(activeSessionProvider.notifier).discard();
      context.pop();
    }
  }
}

// ── Progress chip ─────────────────────────────────────────────────────────────

class _ProgressChip extends StatelessWidget {
  final Session session;
  const _ProgressChip({required this.session});

  @override
  Widget build(BuildContext context) {
    final done = session.completedBlocksCount;
    final total = session.exerciseBlocks.length;

    final theme = Theme.of(context);
    final complete = done == total && total > 0;
    return AnimatedContainer(
      duration: WayMotion.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: complete
            ? AppColors.accent.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: complete
              ? AppColors.accent.withValues(alpha: 0.4)
              : theme.colorScheme.outline,
        ),
      ),
      child: Text(
        '$done / $total',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: complete ? AppColors.accent : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ── Bottom bar with complete button ──────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final ActiveSessionState state;
  const _BottomBar({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canComplete = state.session.hasAnyWork;

    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(0, -2),
            blurRadius: 14,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: FilledButton(
            key: AppKeys.completeSessionButton,
            onPressed: canComplete && !state.isSubmitting
                ? () => _completeWorkout(context, ref)
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Text('Complete workout'),
          ),
        ),
      ),
    );
  }

  Future<void> _completeWorkout(BuildContext context, WidgetRef ref) async {
    String? notes;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CompleteWorkoutSheet(
        onNotesChanged: (v) => notes = v,
      ),
    );
    if (confirmed != true) return;

    final session = await ref
        .read(activeSessionProvider.notifier)
        .completeSession(notes: notes);

    if (session != null && context.mounted) {
      context.pushReplacement(Routes.sessionSummary(session.id));
    }
  }
}

// ── Complete workout bottom sheet ─────────────────────────────────────────────

class _CompleteWorkoutSheet extends StatefulWidget {
  final ValueChanged<String> onNotesChanged;
  const _CompleteWorkoutSheet({required this.onNotesChanged});

  @override
  State<_CompleteWorkoutSheet> createState() => _CompleteWorkoutSheetState();
}

class _CompleteWorkoutSheetState extends State<_CompleteWorkoutSheet> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Finish workout',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Anything worth remembering?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: AppKeys.sessionNotesField,
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'How did it feel…',
            ),
            onChanged: widget.onNotesChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save & finish'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Exercise block card ───────────────────────────────────────────────────────

class _ExerciseBlockCard extends ConsumerStatefulWidget {
  final ExerciseBlock block;
  final int index;
  final bool isCurrent;

  const _ExerciseBlockCard({
    required this.block,
    required this.index,
    required this.isCurrent,
  });

  @override
  ConsumerState<_ExerciseBlockCard> createState() => _ExerciseBlockCardState();
}

class _ExerciseBlockCardState extends ConsumerState<_ExerciseBlockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: WayMotion.settled,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: WayMotion.easeSettled,
    ));

    _expanded = widget.isCurrent;

    Future.delayed(
      Duration(milliseconds: 60 * widget.index),
      () {
        if (mounted) _slideController.forward();
      },
    );
  }

  @override
  void didUpdateWidget(covariant _ExerciseBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !oldWidget.isCurrent) {
      setState(() => _expanded = true);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;
    final complete =
        block.isStarted && block.completedSetsCount >= block.plannedSets;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _slideController,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: WayMotion.standard,
              curve: WayMotion.easeStandard,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: complete
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : theme.colorScheme.outline,
                ),
              ),
              padding: EdgeInsets.only(left: widget.isCurrent ? 4 : 0),
              child: Column(
                children: [
                  _ExerciseBlockHeader(
                    block: block,
                    expanded: _expanded,
                    complete: complete,
                    onToggle: () => setState(() => _expanded = !_expanded),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _ExerciseBlockBody(block: block),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: WayMotion.standard,
                  ),
                ],
              ),
            ),
            if (widget.isCurrent)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise block header (exercise name + planned sets) ─────────────────────

class _ExerciseBlockHeader extends ConsumerWidget {
  final ExerciseBlock block;
  final bool expanded;
  final bool complete;
  final VoidCallback onToggle;

  const _ExerciseBlockHeader({
    required this.block,
    required this.expanded,
    required this.complete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final exercisesAsync = ref.watch(exerciseListProvider);
    final exercise = exercisesAsync.maybeWhen(
      data: (list) => list.where((e) => e.id == block.exerciseId).firstOrNull,
      orElse: () => null,
    );

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md - 2,
          AppSpacing.sm + 4,
          AppSpacing.md - 2,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: WayMotion.standard,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: complete
                    ? AppColors.accent
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                complete ? Icons.check : Icons.self_improvement,
                size: 16,
                color: complete
                    ? AppColors.textOnPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise?.name ?? block.category ?? block.exerciseId,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${block.plannedSets} sets × ${block.plannedReps}'
                    '${block.completedSetsCount > 0 ? ' · ${block.completedSetsCount} done' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              duration: WayMotion.micro,
              turns: expanded ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise block body (set rows + RPE) ─────────────────────────────────────

class _ExerciseBlockBody extends ConsumerStatefulWidget {
  final ExerciseBlock block;
  const _ExerciseBlockBody({required this.block});

  @override
  ConsumerState<_ExerciseBlockBody> createState() => _ExerciseBlockBodyState();
}

class _ExerciseBlockBodyState extends ConsumerState<_ExerciseBlockBody> {
  // Local text controllers per set
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};

  @override
  void dispose() {
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _repsController(int setNum, String plannedReps) {
    return _repsControllers.putIfAbsent(
      setNum,
      () => TextEditingController(text: plannedReps),
    );
  }

  TextEditingController _weightController(int setNum) {
    return _weightControllers.putIfAbsent(
      setNum,
      () => TextEditingController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;
    final totalSets = block.plannedSets;

    // Build rows for planned sets (plus any extra logged sets)
    final maxSets = totalSets > block.actualSets.length
        ? totalSets
        : block.actualSets.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSpacing.sm + 4),
          for (int setNum = 1; setNum <= maxSets; setNum++)
            _SetRow(
              setNumber: setNum,
              block: block,
              repsController: _repsController(setNum, block.plannedReps),
              weightController: _weightController(setNum),
              onToggle: (completed) {
                final reps = int.tryParse(
                  _repsControllers[setNum]?.text ?? '',
                );
                final weight = _weightControllers[setNum]?.text.trim();
                ref.read(activeSessionProvider.notifier).recordSet(
                      block.exerciseId,
                      SetEntry(
                        setNumber: setNum,
                        reps: reps,
                        weight: weight?.isNotEmpty == true ? weight : null,
                        completed: completed,
                      ),
                    );
              },
            ),
          const SizedBox(height: AppSpacing.md),
          _RpeSelector(
            exerciseId: block.exerciseId,
            currentRpe: block.rpe,
          ),
        ],
      ),
    );
  }
}

// ── Individual set row ────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final int setNumber;
  final ExerciseBlock block;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final ValueChanged<bool> onToggle;

  const _SetRow({
    required this.setNumber,
    required this.block,
    required this.repsController,
    required this.weightController,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = block.actualSets
        .where((s) => s.setNumber == setNumber && s.completed)
        .isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(!isCompleted),
            child: AnimatedContainer(
              duration: WayMotion.standard,
              curve: WayMotion.easeStandard,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.accent
                      : theme.colorScheme.outline,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.textOnPrimary,
                      )
                    : Text(
                        '$setNumber',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'reps',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: weightController,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'kg',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ── RPE selector ─────────────────────────────────────────────────────────────

class _RpeSelector extends ConsumerWidget {
  final String exerciseId;
  final int? currentRpe;

  const _RpeSelector({required this.exerciseId, required this.currentRpe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Effort',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.accent,
                        AppColors.warning,
                        AppColors.primary,
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(10, (i) {
                    final rpe = i + 1;
                    final selected = currentRpe == rpe;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ref
                            .read(activeSessionProvider.notifier)
                            .setRpe(exerciseId, rpe),
                        child: SizedBox(
                          height: AppSpacing.minTapTarget / 2,
                          child: selected
                              ? const SizedBox.shrink()
                              : const SizedBox.shrink(),
                        ),
                      ),
                    );
                  }),
                ),
                if (currentRpe != null)
                  AnimatedPositioned(
                    duration: WayMotion.standard,
                    curve: WayMotion.easeStandard,
                    left: ((currentRpe! - 1) / 9) * (trackWidth - 18),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            currentRpe == null ? 'Tap to set' : 'RPE $currentRpe / 10',
            style: AppTypography.manrope(
              size: 12,
              weight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}
