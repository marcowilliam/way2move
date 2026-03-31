import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/food_item.dart';
import '../entities/meal.dart';
import '../repositories/meal_repository.dart';
import 'get_weekly_nutrition_summary.dart';

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late MockMealRepository mockRepo;
  late GetWeeklyNutritionSummary useCase;

  setUp(() {
    mockRepo = MockMealRepository();
    useCase = GetWeeklyNutritionSummary(mockRepo);
  });

  Meal makeMeal({
    required DateTime date,
    int stomachFeeling = 3,
    List<FoodItem>? foodItems,
  }) =>
      Meal(
        id: 'meal-${date.millisecondsSinceEpoch}',
        userId: 'user1',
        date: date,
        mealType: MealType.lunch,
        description: 'test meal',
        stomachFeeling: stomachFeeling,
        foodItems: foodItems,
      );

  group('GetWeeklyNutritionSummary', () {
    test('returns 7 days of summaries', () async {
      when(() => mockRepo.getMealsByDateRange('user1', any(), any()))
          .thenAnswer((_) async => const Right([]));

      final result = await useCase('user1', DateTime(2026, 3, 31));

      expect(result.isRight(), true);
      expect(result.getRight().getOrElse(() => []).length, 7);
    });

    test('empty days have mealCount 0', () async {
      when(() => mockRepo.getMealsByDateRange('user1', any(), any()))
          .thenAnswer((_) async => const Right([]));

      final result = await useCase('user1', DateTime(2026, 3, 31));
      final summaries = result.getRight().getOrElse(() => []);

      for (final s in summaries) {
        expect(s.mealCount, 0);
        expect(s.totalCalories, 0);
        expect(s.hasData, false);
      }
    });

    test('aggregates meals into correct day', () async {
      final meals = [
        makeMeal(
          date: DateTime(2026, 3, 31, 8),
          stomachFeeling: 4,
          foodItems: [
            const FoodItem(
                name: 'Rice', calories: 130, protein: 3, carbs: 28, fat: 0.3),
          ],
        ),
        makeMeal(
          date: DateTime(2026, 3, 31, 12),
          stomachFeeling: 2,
          foodItems: [
            const FoodItem(
                name: 'Chicken',
                calories: 165,
                protein: 31,
                carbs: 0,
                fat: 3.6),
          ],
        ),
      ];

      when(() => mockRepo.getMealsByDateRange('user1', any(), any()))
          .thenAnswer((_) async => Right(meals));

      final result = await useCase('user1', DateTime(2026, 3, 31));
      final summaries = result.getRight().getOrElse(() => []);
      final lastDay = summaries.last;

      expect(lastDay.mealCount, 2);
      expect(lastDay.totalCalories, closeTo(295, 0.1));
      expect(lastDay.totalProtein, closeTo(34, 0.1));
      expect(lastDay.avgStomachFeeling, 3.0);
    });

    test('returns Left on repository failure', () async {
      when(() => mockRepo.getMealsByDateRange('user1', any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase('user1', DateTime(2026, 3, 31));

      expect(result.isLeft(), true);
    });
  });
}
