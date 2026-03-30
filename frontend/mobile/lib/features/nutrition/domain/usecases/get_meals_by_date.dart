import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/meal.dart';
import '../repositories/meal_repository.dart';

class GetMealsByDate {
  final MealRepository _repo;
  const GetMealsByDate(this._repo);

  Future<Either<AppFailure, List<Meal>>> call(String userId, DateTime date) =>
      _repo.getMealsByDate(userId, date);
}
