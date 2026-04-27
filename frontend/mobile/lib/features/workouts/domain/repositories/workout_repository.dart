import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/workout.dart';
import '../entities/workout_enums.dart';

abstract class WorkoutRepository {
  /// One-shot read of all workouts for the user. Optional `kind` filter.
  Future<Either<AppFailure, List<Workout>>> getWorkouts(
    String userId, {
    WorkoutKind? kind,
  });

  /// Live stream of the user's workouts. Drives Workout Library UI.
  Stream<List<Workout>> watchWorkouts(String userId, {WorkoutKind? kind});

  Future<Either<AppFailure, Workout>> getWorkoutById(String workoutId);

  Future<Either<AppFailure, Workout>> createWorkout(Workout workout);

  Future<Either<AppFailure, Workout>> updateWorkout(Workout workout);

  Future<Either<AppFailure, void>> deleteWorkout(String workoutId);
}
