import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/food_item.dart';
import '../entities/meal.dart';
import '../repositories/meal_repository.dart';
import 'get_stomach_food_correlations.dart';

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late MockMealRepository mockRepo;
  late GetStomachFoodCorrelations useCase;

  setUp(() {
    mockRepo = MockMealRepository();
    useCase = GetStomachFoodCorrelations(mockRepo);
  });

  Meal makeMeal({
    required int stomachFeeling,
    required List<FoodItem> foodItems,
    DateTime? date,
  }) =>
      Meal(
        id: 'meal-${DateTime.now().microsecondsSinceEpoch}',
        userId: 'user1',
        date: date ?? DateTime.now(),
        mealType: MealType.lunch,
        description: 'test',
        stomachFeeling: stomachFeeling,
        foodItems: foodItems,
      );

  const chicken =
      FoodItem(name: 'Chicken', calories: 165, protein: 31, carbs: 0, fat: 4);
  const dairy =
      FoodItem(name: 'Dairy', calories: 100, protein: 8, carbs: 12, fat: 4);

  group('GetStomachFoodCorrelations', () {
    test('returns foods sorted by avg stomach feeling ascending', () async {
      final meals = [
        makeMeal(stomachFeeling: 1, foodItems: [dairy]),
        makeMeal(stomachFeeling: 2, foodItems: [dairy]),
        makeMeal(stomachFeeling: 4, foodItems: [chicken]),
        makeMeal(stomachFeeling: 5, foodItems: [chicken]),
      ];

      when(() => mockRepo.getMealsByDateRange('user1', any(), any()))
          .thenAnswer((_) async => Right(meals));

      final result = await useCase('user1');
      final correlations = result.getRight().getOrElse(() => []);

      expect(correlations.length, 2);
      expect(correlations.first.foodName, 'dairy');
      expect(correlations.first.avgStomachFeeling, 1.5);
      expect(correlations.first.isProblematic, true);
      expect(correlations.last.foodName, 'chicken');
      expect(correlations.last.avgStomachFeeling, 4.5);
      expect(correlations.last.isProblematic, false);
    });

    test('filters out foods with fewer than 2 occurrences', () async {
      final meals = [
        makeMeal(stomachFeeling: 1, foodItems: [dairy]),
        makeMeal(stomachFeeling: 4, foodItems: [chicken]),
        makeMeal(stomachFeeling: 5, foodItems: [chicken]),
      ];

      when(() => mockRepo.getMealsByDateRange('user1', any(), any()))
          .thenAnswer((_) async => Right(meals));

      final result = await useCase('user1');
      final correlations = result.getRight().getOrElse(() => []);

      expect(correlations.length, 1);
      expect(correlations.first.foodName, 'chicken');
    });

    test('skips meals without food items', () async {
      final meals = [
        Meal(
          id: 'm1',
          userId: 'user1',
          date: DateTime.now(),
          mealType: MealType.lunch,
          description: 'just a description',
          stomachFeeling: 1,
        ),
      ];

      when(() => mockRepo.getMealsByDateRange('user1', any(), any()))
          .thenAnswer((_) async => Right(meals));

      final result = await useCase('user1');
      expect(result.getRight().getOrElse(() => []).length, 0);
    });

    test('returns Left on failure', () async {
      when(() => mockRepo.getMealsByDateRange('user1', any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase('user1');
      expect(result.isLeft(), true);
    });
  });
}
