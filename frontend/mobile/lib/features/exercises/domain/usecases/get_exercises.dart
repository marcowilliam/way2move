import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/exercise.dart';
import '../repositories/exercise_repository.dart';

class GetExercises {
  final ExerciseRepository _repo;
  const GetExercises(this._repo);

  Future<Either<AppFailure, List<Exercise>>> call() => _repo.getExercises();
}
