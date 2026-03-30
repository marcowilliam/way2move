import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/meal.dart';
import '../repositories/meal_repository.dart';

class UpdateMeal {
  final MealRepository _repo;
  const UpdateMeal(this._repo);

  Future<Either<AppFailure, Meal>> call(Meal meal) => _repo.updateMeal(meal);
}
