import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/workout.dart';
import '../entities/workout_enums.dart';
import '../repositories/workout_repository.dart';

class GetWorkouts {
  final WorkoutRepository _repo;
  const GetWorkouts(this._repo);

  Future<Either<AppFailure, List<Workout>>> call(
    String userId, {
    WorkoutKind? kind,
  }) =>
      _repo.getWorkouts(userId, kind: kind);
}
