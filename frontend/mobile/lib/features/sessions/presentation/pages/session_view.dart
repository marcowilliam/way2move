import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
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
      duration: const Duration(milliseconds: 400),
    )..forward();
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
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

    return Scaffold(
      key: AppKeys.sessionView,
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _confirmExit(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: FadeTransition(
                opacity: _headerFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.focus ?? 'Workout',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatDate(session.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 12, right: 16),
            ),
            actions: [
              _ProgressChip(session: session),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final block = session.exerciseBlocks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExerciseBlockCard(
                      block: block,
                      index: index,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: done == total && total > 0
            ? AppColors.accentGreen.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$done / $total',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: done == total && total > 0
                  ? AppColors.accentGreen
                  : Theme.of(context).colorScheme.onSurface,
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: FilledButton(
          key: AppKeys.completeSessionButton,
          onPressed: canComplete && !state.isSubmitting
              ? () => _completeWorkout(context, ref)
              : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: state.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Complete Workout'),
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
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
          const SizedBox(height: 20),
          Text(
            'Finish Workout',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Add any notes before saving.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: AppKeys.sessionNotesField,
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'How did it feel? Any observations...',
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onNotesChanged,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save & Finish'),
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

  const _ExerciseBlockCard({required this.block, required this.index});

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
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Stagger entrance animation by index
    Future.delayed(
      Duration(milliseconds: 60 * widget.index),
      () {
        if (mounted) _slideController.forward();
      },
    );
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

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _slideController,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: block.isStarted
                  ? AppColors.accentGreen.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              _ExerciseBlockHeader(
                block: block,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _ExerciseBlockBody(block: block),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Exercise block header (exercise name + planned sets) ─────────────────────

class _ExerciseBlockHeader extends ConsumerWidget {
  final ExerciseBlock block;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExerciseBlockHeader({
    required this.block,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Fetch exercise name from cache
    final exercisesAsync = ref.watch(exerciseListProvider);
    final exercise = exercisesAsync.maybeWhen(
      data: (list) => list.where((e) => e.id == block.exerciseId).firstOrNull,
      orElse: () => null,
    );

    return InkWell(
      onTap: onToggle,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            // Completion indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: block.isStarted
                    ? AppColors.accentGreen
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                block.isStarted ? Icons.check : Icons.fitness_center,
                size: 16,
                color: block.isStarted
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise?.name ?? block.exerciseId,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${block.plannedSets} sets × ${block.plannedReps}'
                    '${block.completedSetsCount > 0 ? ' · ${block.completedSetsCount} done' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: expanded ? 0.5 : 0,
              child: const Icon(Icons.keyboard_arrow_down),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Column headers
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  'Set',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reps',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weight',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          // Set rows
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
          // RPE row
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  '$setNumber',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isCompleted
                        ? AppColors.accentGreen
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: const OutlineInputBorder(),
                filled: isCompleted,
                fillColor: isCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.07)
                    : null,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: weightController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: const OutlineInputBorder(),
                hintText: 'kg / BW',
                filled: isCompleted,
                fillColor: isCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.07)
                    : null,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: () => onToggle(!isCompleted),
              style: IconButton.styleFrom(
                backgroundColor: isCompleted
                    ? AppColors.accentGreen
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor:
                    isCompleted ? Colors.white : theme.colorScheme.onSurface,
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isCompleted ? Icons.check : Icons.radio_button_unchecked,
                  key: ValueKey(isCompleted),
                  size: 18,
                ),
              ),
              iconSize: 18,
              padding: EdgeInsets.zero,
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
          'Effort (RPE)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(10, (i) {
            final rpe = i + 1;
            final selected = currentRpe == rpe;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref
                    .read(activeSessionProvider.notifier)
                    .setRpe(exerciseId, rpe),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: selected
                        ? _rpeColor(rpe)
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Text(
                      '$rpe',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _rpeColor(int rpe) {
    if (rpe <= 3) return AppColors.accentGreen;
    if (rpe <= 6) return AppColors.accent;
    return AppColors.accentRed;
  }
}
