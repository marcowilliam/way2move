import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/exercise.dart';
import '../repositories/exercise_repository.dart';

class AddExercise {
  final ExerciseRepository _repo;
  const AddExercise(this._repo);

  Future<Either<AppFailure, Exercise>> call(Exercise exercise) =>
      _repo.addCustomExercise(exercise);
}
