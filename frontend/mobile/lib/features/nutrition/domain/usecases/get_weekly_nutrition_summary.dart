import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/daily_nutrition_summary.dart';
import '../entities/meal.dart';
import '../repositories/meal_repository.dart';

class GetWeeklyNutritionSummary {
  final MealRepository _repo;
  const GetWeeklyNutritionSummary(this._repo);

  /// Returns 7 [DailyNutritionSummary] entries for the week ending on [endDate].
  /// Days with no meals return a summary with zeroes and mealCount 0.
  Future<Either<AppFailure, List<DailyNutritionSummary>>> call(
    String userId,
    DateTime endDate,
  ) async {
    final end = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));
    final start = end.subtract(const Duration(days: 7));

    final result = await _repo.getMealsByDateRange(userId, start, end);
    return result.map((meals) => _buildWeek(start, meals));
  }

  List<DailyNutritionSummary> _buildWeek(DateTime start, List<Meal> meals) {
    final Map<int, List<Meal>> byDay = {};
    for (final meal in meals) {
      final dayKey = meal.date.difference(start).inDays;
      byDay.putIfAbsent(dayKey, () => []).add(meal);
    }

    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final dayMeals = byDay[i] ?? [];
      if (dayMeals.isEmpty) {
        return DailyNutritionSummary(
          date: day,
          totalCalories: 0,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          mealCount: 0,
          avgStomachFeeling: 0,
        );
      }
      return DailyNutritionSummary(
        date: day,
        totalCalories: dayMeals.fold(0.0, (s, m) => s + m.totalCalories),
        totalProtein: dayMeals.fold(0.0, (s, m) => s + m.totalProtein),
        totalCarbs: dayMeals.fold(0.0, (s, m) => s + m.totalCarbs),
        totalFat: dayMeals.fold(0.0, (s, m) => s + m.totalFat),
        mealCount: dayMeals.length,
        avgStomachFeeling:
            dayMeals.map((m) => m.stomachFeeling).reduce((a, b) => a + b) /
                dayMeals.length,
      );
    });
  }
}
