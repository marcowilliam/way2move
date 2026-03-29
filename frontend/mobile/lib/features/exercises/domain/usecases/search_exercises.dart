import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/exercise.dart';
import '../repositories/exercise_repository.dart';

class SearchExercises {
  final ExerciseRepository _repo;
  const SearchExercises(this._repo);

  Future<Either<AppFailure, List<Exercise>>> call(String query) =>
      _repo.searchExercises(query);
}
