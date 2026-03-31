import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../repositories/meal_repository.dart';

class GetLoggingStreak {
  final MealRepository _repo;
  const GetLoggingStreak(this._repo);

  /// Returns the number of consecutive days (ending today) with at least 1 meal.
  Future<Either<AppFailure, int>> call(String userId) async {
    final result = await _repo.getMealHistory(userId, limit: 500);
    return result.map((meals) {
      if (meals.isEmpty) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Collect unique days (as days-ago offset)
      final Set<int> daysWithMeals = {};
      for (final meal in meals) {
        final mealDay =
            DateTime(meal.date.year, meal.date.month, meal.date.day);
        final diff = today.difference(mealDay).inDays;
        if (diff >= 0) daysWithMeals.add(diff);
      }

      // Count consecutive days starting from today
      int streak = 0;
      while (daysWithMeals.contains(streak)) {
        streak++;
      }
      return streak;
    });
  }
}
