import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/exercise.dart';

abstract class ExerciseRepository {
  Future<Either<AppFailure, List<Exercise>>> getExercises();
  Future<Either<AppFailure, Exercise>> getExerciseById(String id);
  Future<Either<AppFailure, List<Exercise>>> searchExercises(String query);
  Future<Either<AppFailure, List<Exercise>>> filterExercises({
    List<SportTag>? sportTags,
    List<ExerciseType>? typeTags,
    List<BodyRegion>? regionTags,
    List<EquipmentTag>? equipmentTags,
    ExerciseDifficulty? difficulty,
  });
  Future<Either<AppFailure, Exercise>> addCustomExercise(Exercise exercise);
}
