import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/stomach_food_correlation.dart';
import '../repositories/meal_repository.dart';

class GetStomachFoodCorrelations {
  final MealRepository _repo;
  const GetStomachFoodCorrelations(this._repo);

  /// Analyzes meals over the last 30 days and returns foods ranked
  /// by average stomach feeling. Requires at least 2 occurrences.
  Future<Either<AppFailure, List<StomachFoodCorrelation>>> call(
    String userId,
  ) async {
    final now = DateTime.now();
    final end =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final start = end.subtract(const Duration(days: 30));

    final result = await _repo.getMealsByDateRange(userId, start, end);
    return result.map((meals) {
      final Map<String, List<int>> foodFeelings = {};

      for (final meal in meals) {
        if (meal.foodItems == null) continue;
        for (final item in meal.foodItems!) {
          final key = item.name.toLowerCase().trim();
          foodFeelings.putIfAbsent(key, () => []).add(meal.stomachFeeling);
        }
      }

      final correlations = foodFeelings.entries
          .where((e) => e.value.length >= 2)
          .map((e) => StomachFoodCorrelation(
                foodName: e.key,
                avgStomachFeeling:
                    e.value.reduce((a, b) => a + b) / e.value.length,
                occurrences: e.value.length,
              ))
          .toList()
        ..sort((a, b) => a.avgStomachFeeling.compareTo(b.avgStomachFeeling));

      return correlations;
    });
  }
}
