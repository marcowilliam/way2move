import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class GetWorkoutById {
  final WorkoutRepository _repo;
  const GetWorkoutById(this._repo);

  Future<Either<AppFailure, Workout>> call(String workoutId) =>
      _repo.getWorkoutById(workoutId);
}
