import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exercise.dart';
import '../providers/exercise_providers.dart';
import '../widgets/exercise_card.dart';

class ExerciseListPage extends ConsumerStatefulWidget {
  const ExerciseListPage({super.key});

  @override
  ConsumerState<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends ConsumerState<ExerciseListPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);
    final filter = ref.watch(exerciseFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.exerciseList,
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: !filter.isEmpty,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filter',
          ),
          IconButton(
            key: AppKeys.addExerciseButton,
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseDialog(context),
            tooltip: 'Add custom exercise',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: AppKeys.exerciseSearchField,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(exerciseSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (v) =>
                  ref.read(exerciseSearchQueryProvider.notifier).state = v,
            ),
          ),
          if (!filter.isEmpty) _ActiveFiltersRow(filter: filter),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) => exercises.isEmpty
                  ? _EmptyState(
                      isFiltered: !filter.isEmpty ||
                          _searchController.text.isNotEmpty)
                  : _ExerciseListView(
                      exercises: exercises,
                      animation: _listController,
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Could not load exercises',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: AppColors.accentRed),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _AddExerciseDialog(),
    );
  }
}

// ── Exercise List View ─────────────────────────────────────────────────────

class _ExerciseListView extends StatelessWidget {
  final List<Exercise> exercises;
  final AnimationController animation;

  const _ExerciseListView({
    required this.exercises,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: exercises.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        final interval = Interval(
          (index * 0.05).clamp(0.0, 0.8),
          ((index * 0.05) + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (_, child) {
            final t = interval.transform(animation.value);
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - t)),
                child: child,
              ),
            );
          },
          child: ExerciseCard(
            exercise: exercises[index],
            onTap: () => context.push(
              Routes.exerciseDetail(exercises[index].id),
            ),
          ),
        );
      },
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.fitness_center_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No exercises match your filters' : 'No exercises yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Active Filters Row ────────────────────────────────────────────────────

class _ActiveFiltersRow extends ConsumerWidget {
  final ExerciseFilter filter;
  const _ActiveFiltersRow({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ...filter.typeTags.map((t) => _FilterChip(
                label: t.name,
                onRemove: () {
                  final tags = List<ExerciseType>.from(filter.typeTags)
                    ..remove(t);
                  ref.read(exerciseFilterProvider.notifier).state =
                      filter.copyWith(typeTags: tags);
                },
              )),
          ...filter.regionTags.map((t) => _FilterChip(
                label: t.name,
                onRemove: () {
                  final tags = List<BodyRegion>.from(filter.regionTags)
                    ..remove(t);
                  ref.read(exerciseFilterProvider.notifier).state =
                      filter.copyWith(regionTags: tags);
                },
              )),
          ...filter.equipmentTags.map((t) => _FilterChip(
                label: t.name,
                onRemove: () {
                  final tags = List<EquipmentTag>.from(filter.equipmentTags)
                    ..remove(t);
                  ref.read(exerciseFilterProvider.notifier).state =
                      filter.copyWith(equipmentTags: tags);
                },
              )),
          if (filter.difficulty != null)
            _FilterChip(
              label: filter.difficulty!.name,
              onRemove: () {
                ref.read(exerciseFilterProvider.notifier).state =
                    filter.copyWith(clearDifficulty: true);
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.close, size: 14),
            label: const Text('Clear all'),
            onPressed: () {
              ref.read(exerciseFilterProvider.notifier).state =
                  const ExerciseFilter();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Filter Sheet ──────────────────────────────────────────────────────────

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(exerciseFilterProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          controller: scrollController,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filter Exercises', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            _FilterSection<ExerciseType>(
              title: 'Type',
              options: ExerciseType.values,
              selected: filter.typeTags,
              label: (t) => t.name,
              onChanged: (tags) => ref
                  .read(exerciseFilterProvider.notifier)
                  .state = filter.copyWith(typeTags: tags),
            ),
            _FilterSection<BodyRegion>(
              title: 'Body Region',
              options: BodyRegion.values,
              selected: filter.regionTags,
              label: (t) => t.name,
              onChanged: (tags) => ref
                  .read(exerciseFilterProvider.notifier)
                  .state = filter.copyWith(regionTags: tags),
            ),
            _FilterSection<EquipmentTag>(
              title: 'Equipment',
              options: EquipmentTag.values,
              selected: filter.equipmentTags,
              label: (t) => t.name,
              onChanged: (tags) => ref
                  .read(exerciseFilterProvider.notifier)
                  .state = filter.copyWith(equipmentTags: tags),
            ),
            const SizedBox(height: 8),
            Text('Difficulty', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: ExerciseDifficulty.values
                  .map((d) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(d.name),
                          selected: filter.difficulty == d,
                          onSelected: (v) {
                            ref
                                .read(exerciseFilterProvider.notifier)
                                .state = v
                                ? filter.copyWith(difficulty: d)
                                : filter.copyWith(clearDifficulty: true);
                          },
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(exerciseFilterProvider.notifier).state =
                          const ExerciseFilter();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final List<T> selected;
  final String Function(T) label;
  final ValueChanged<List<T>> onChanged;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options
              .map((opt) => FilterChip(
                    label: Text(label(opt)),
                    selected: selected.contains(opt),
                    onSelected: (v) {
                      final list = List<T>.from(selected);
                      if (v) {
                        list.add(opt);
                      } else {
                        list.remove(opt);
                      }
                      onChanged(list);
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Add Exercise Dialog ────────────────────────────────────────────────────

class _AddExerciseDialog extends ConsumerStatefulWidget {
  const _AddExerciseDialog();

  @override
  ConsumerState<_AddExerciseDialog> createState() =>
      _AddExerciseDialogState();
}

class _AddExerciseDialogState extends ConsumerState<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _videoController = TextEditingController();
  ExerciseDifficulty _difficulty = ExerciseDifficulty.beginner;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add custom exercise'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _videoController,
                decoration:
                    const InputDecoration(labelText: 'Video URL (optional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Difficulty', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: ExerciseDifficulty.values
                        .map((d) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(d.name),
                                selected: _difficulty == d,
                                onSelected: (_) =>
                                    setState(() => _difficulty = d),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAdd,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final exercise = Exercise(
      id: '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      videoUrl: _videoController.text.trim(),
      difficulty: _difficulty,
      isCustom: true,
    );

    final success =
        await ref.read(addExerciseProvider.notifier).add(exercise);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise added!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add exercise')),
      );
    }
  }
}
