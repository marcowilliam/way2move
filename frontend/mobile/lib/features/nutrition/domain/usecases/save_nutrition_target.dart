import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/nutrition_target.dart';
import '../repositories/nutrition_target_repository.dart';

class SaveNutritionTarget {
  final NutritionTargetRepository _repo;
  const SaveNutritionTarget(this._repo);

  Future<Either<AppFailure, NutritionTarget>> call(NutritionTarget target) =>
      _repo.saveTarget(target);
}
