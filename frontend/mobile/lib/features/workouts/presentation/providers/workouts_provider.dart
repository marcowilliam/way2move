import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_enums.dart';

/// Live list of the current user's workouts. Drives the Workout Library
/// page. Pass an optional `kind` to filter; pass `null` for "all".
final workoutsProvider =
    StreamProvider.family<List<Workout>, WorkoutKind?>((ref, kind) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchWorkouts(userId, kind: kind);
});

/// One-shot read of a workout by id. Drives the Workout Detail page.
final workoutByIdProvider =
    FutureProvider.family<Workout?, String>((ref, id) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final res = await repo.getWorkoutById(id);
  return res.fold((_) => null, (w) => w);
});
