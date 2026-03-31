import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/nutrition_target.dart';
import '../repositories/nutrition_target_repository.dart';

class GetNutritionTarget {
  final NutritionTargetRepository _repo;
  const GetNutritionTarget(this._repo);

  Future<Either<AppFailure, NutritionTarget?>> call(String userId) =>
      _repo.getTarget(userId);
}
