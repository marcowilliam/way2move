import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/meal.dart';

abstract class MealRepository {
  Future<Either<AppFailure, Meal>> createMeal(Meal meal);
  Future<Either<AppFailure, Meal>> updateMeal(Meal meal);
  Future<Either<AppFailure, Unit>> deleteMeal(String mealId);
  Future<Either<AppFailure, List<Meal>>> getMealsByDate(
      String userId, DateTime date);
  Future<Either<AppFailure, List<Meal>>> getMealHistory(String userId,
      {int limit});
}
