import '../entities/workout.dart';
import '../entities/workout_enums.dart';
import '../repositories/workout_repository.dart';

/// Live stream of the user's workouts. UI subscribes via a StreamProvider.
class WatchWorkouts {
  final WorkoutRepository _repo;
  const WatchWorkouts(this._repo);

  Stream<List<Workout>> call(String userId, {WorkoutKind? kind}) =>
      _repo.watchWorkouts(userId, kind: kind);
}
