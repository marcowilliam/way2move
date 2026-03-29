import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../exercises/domain/entities/exercise.dart';
import '../../../exercises/presentation/providers/exercise_providers.dart';
import '../../domain/entities/session.dart';
import '../providers/session_providers.dart';

class CreateStandaloneSessionPage extends ConsumerStatefulWidget {
  const CreateStandaloneSessionPage({super.key});

  @override
  ConsumerState<CreateStandaloneSessionPage> createState() =>
      _CreateStandaloneSessionPageState();
}

class _CreateStandaloneSessionPageState
    extends ConsumerState<CreateStandaloneSessionPage>
    with SingleTickerProviderStateMixin {
  final List<_SelectedExercise> _selected = [];
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.standaloneSessionPage,
      appBar: AppBar(
        title: const Text('Quick Workout'),
        centerTitle: true,
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              key: AppKeys.startWorkoutButton,
              onPressed: _startWorkout,
              child: Text(
                'Start (${_selected.length})',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selected.isNotEmpty)
            _SelectedExerciseList(
              selected: _selected,
              onRemove: (index) => setState(() => _selected.removeAt(index)),
              onSetsChanged: (index, sets) =>
                  setState(() => _selected[index].sets = sets),
              onRepsChanged: (index, reps) =>
                  setState(() => _selected[index].reps = reps),
            ),
          Expanded(
            child: _ExercisePicker(
              alreadySelectedIds: _selected.map((s) => s.exercise.id).toSet(),
              onAdd: (exercise) {
                setState(() {
                  _selected.add(_SelectedExercise(exercise: exercise));
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  key: AppKeys.startWorkoutButton,
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Start Workout (${_selected.length} exercises)'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _startWorkout() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _selected.isEmpty) return;

    final blocks = _selected
        .map((s) => ExerciseBlock(
              exerciseId: s.exercise.id,
              plannedSets: s.sets,
              plannedReps: s.reps,
            ))
        .toList();

    final session = Session(
      id: '',
      userId: userId,
      date: DateTime.now(),
      status: SessionStatus.inProgress,
      exerciseBlocks: blocks,
    );

    ref.read(activeSessionProvider.notifier).loadSession(session);
    if (mounted) {
      context.pushReplacement(Routes.sessionActive);
    }
  }
}

// ── Selected exercise model ───────────────────────────────────────────────────

class _SelectedExercise {
  final Exercise exercise;
  int sets = 3;
  String reps = '10';

  _SelectedExercise({required this.exercise});
}

// ── Selected exercise list ────────────────────────────────────────────────────

class _SelectedExerciseList extends StatelessWidget {
  final List<_SelectedExercise> selected;
  final ValueChanged<int> onRemove;
  final void Function(int index, int sets) onSetsChanged;
  final void Function(int index, String reps) onRepsChanged;

  const _SelectedExerciseList({
    required this.selected,
    required this.onRemove,
    required this.onSetsChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      constraints: const BoxConstraints(maxHeight: 240),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: selected.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = selected[index];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              item.exercise.name,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Row(
              children: [
                _MiniSpinner(
                  label: 'Sets',
                  value: item.sets,
                  min: 1,
                  max: 10,
                  onChanged: (v) => onSetsChanged(index, v),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Reps',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    controller: TextEditingController(text: item.reps),
                    onChanged: (v) => onRepsChanged(index, v),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: AppColors.accentRed,
              onPressed: () => onRemove(index),
            ),
          );
        },
      ),
    );
  }
}

class _MiniSpinner extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _MiniSpinner({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                )),
        const SizedBox(width: 4),
        InkWell(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: const Icon(Icons.remove, size: 16),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('$value',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        InkWell(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: const Icon(Icons.add, size: 16),
        ),
      ],
    );
  }
}

// ── Exercise picker (search + list) ─────────────────────────────────────────

class _ExercisePicker extends ConsumerStatefulWidget {
  final Set<String> alreadySelectedIds;
  final ValueChanged<Exercise> onAdd;

  const _ExercisePicker({
    required this.alreadySelectedIds,
    required this.onAdd,
  });

  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            key: AppKeys.addExerciseToSessionButton,
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: exercisesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (exercises) {
              final filtered = _query.isEmpty
                  ? exercises
                  : exercises
                      .where((e) =>
                          e.name.toLowerCase().contains(_query) ||
                          e.description.toLowerCase().contains(_query))
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No exercises found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final exercise = filtered[index];
                  final alreadyAdded =
                      widget.alreadySelectedIds.contains(exercise.id);

                  return ListTile(
                    title: Text(
                      exercise.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: alreadyAdded
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      exercise.typeTags.map((t) => t.name).join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: alreadyAdded
                        ? const Icon(Icons.check_circle,
                            color: AppColors.accentGreen, size: 20)
                        : IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: theme.colorScheme.primary,
                            onPressed: () => widget.onAdd(exercise),
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
