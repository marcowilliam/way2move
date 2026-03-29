import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/exercise_repository_impl.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/usecases/add_exercise.dart';
import '../../domain/usecases/get_exercises.dart';
import '../../domain/usecases/search_exercises.dart';

// Filter state
class ExerciseFilter {
  final List<SportTag> sportTags;
  final List<ExerciseType> typeTags;
  final List<BodyRegion> regionTags;
  final List<EquipmentTag> equipmentTags;
  final ExerciseDifficulty? difficulty;

  const ExerciseFilter({
    this.sportTags = const [],
    this.typeTags = const [],
    this.regionTags = const [],
    this.equipmentTags = const [],
    this.difficulty,
  });

  ExerciseFilter copyWith({
    List<SportTag>? sportTags,
    List<ExerciseType>? typeTags,
    List<BodyRegion>? regionTags,
    List<EquipmentTag>? equipmentTags,
    ExerciseDifficulty? difficulty,
    bool clearDifficulty = false,
  }) {
    return ExerciseFilter(
      sportTags: sportTags ?? this.sportTags,
      typeTags: typeTags ?? this.typeTags,
      regionTags: regionTags ?? this.regionTags,
      equipmentTags: equipmentTags ?? this.equipmentTags,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
    );
  }

  bool get isEmpty =>
      sportTags.isEmpty &&
      typeTags.isEmpty &&
      regionTags.isEmpty &&
      equipmentTags.isEmpty &&
      difficulty == null;
}

final exerciseFilterProvider = StateProvider<ExerciseFilter>(
  (ref) => const ExerciseFilter(),
);

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

final exerciseListProvider = FutureProvider<List<Exercise>>((ref) async {
  final filter = ref.watch(exerciseFilterProvider);
  final query = ref.watch(exerciseSearchQueryProvider);
  final repo = ref.watch(exerciseRepositoryProvider);

  if (query.isNotEmpty) {
    final result = await SearchExercises(repo)(query);
    return result.fold((_) => [], (list) => list);
  }

  if (!filter.isEmpty) {
    final result = await repo.filterExercises(
      sportTags: filter.sportTags.isEmpty ? null : filter.sportTags,
      typeTags: filter.typeTags.isEmpty ? null : filter.typeTags,
      regionTags: filter.regionTags.isEmpty ? null : filter.regionTags,
      equipmentTags:
          filter.equipmentTags.isEmpty ? null : filter.equipmentTags,
      difficulty: filter.difficulty,
    );
    return result.fold((_) => [], (list) => list);
  }

  final result = await GetExercises(repo)();
  return result.fold((_) => [], (list) => list);
});

final exerciseDetailProvider =
    FutureProvider.family<Exercise?, String>((ref, id) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final result = await repo.getExerciseById(id);
  return result.fold((_) => null, (e) => e);
});

class AddExerciseNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> add(Exercise exercise) async {
    final useCase = AddExercise(ref.read(exerciseRepositoryProvider));
    final result = await useCase(exercise);
    if (result.isRight()) {
      ref.invalidate(exerciseListProvider);
    }
    return result.isRight();
  }
}

final addExerciseProvider =
    AsyncNotifierProvider<AddExerciseNotifier, void>(AddExerciseNotifier.new);
