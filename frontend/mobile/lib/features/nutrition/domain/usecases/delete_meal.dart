import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../repositories/meal_repository.dart';

class DeleteMeal {
  final MealRepository _repo;
  const DeleteMeal(this._repo);

  Future<Either<AppFailure, Unit>> call(String mealId) =>
      _repo.deleteMeal(mealId);
}
