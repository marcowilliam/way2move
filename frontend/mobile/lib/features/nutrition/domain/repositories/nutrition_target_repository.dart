import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/nutrition_target.dart';

abstract class NutritionTargetRepository {
  Future<Either<AppFailure, NutritionTarget?>> getTarget(String userId);
  Future<Either<AppFailure, NutritionTarget>> saveTarget(
      NutritionTarget target);
}
