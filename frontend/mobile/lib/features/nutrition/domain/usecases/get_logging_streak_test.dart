import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/meal.dart';
import '../repositories/meal_repository.dart';
import 'get_logging_streak.dart';

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late MockMealRepository mockRepo;
  late GetLoggingStreak useCase;

  setUp(() {
    mockRepo = MockMealRepository();
    useCase = GetLoggingStreak(mockRepo);
  });

  Meal makeMeal(DateTime date) => Meal(
        id: 'meal-${date.millisecondsSinceEpoch}',
        userId: 'user1',
        date: date,
        mealType: MealType.lunch,
        description: 'test',
        stomachFeeling: 3,
      );

  group('GetLoggingStreak', () {
    test('returns 0 when no meals', () async {
      when(() => mockRepo.getMealHistory('user1', limit: 500))
          .thenAnswer((_) async => const Right([]));

      final result = await useCase('user1');
      expect(result.getRight().getOrElse(() => -1), 0);
    });

    test('returns 1 when only today has meals', () async {
      when(() => mockRepo.getMealHistory('user1', limit: 500))
          .thenAnswer((_) async => Right([makeMeal(DateTime.now())]));

      final result = await useCase('user1');
      expect(result.getRight().getOrElse(() => -1), 1);
    });

    test('counts consecutive days correctly', () async {
      final now = DateTime.now();
      final meals = [
        makeMeal(now),
        makeMeal(now.subtract(const Duration(days: 1))),
        makeMeal(now.subtract(const Duration(days: 2))),
        // gap at day 3
        makeMeal(now.subtract(const Duration(days: 4))),
      ];

      when(() => mockRepo.getMealHistory('user1', limit: 500))
          .thenAnswer((_) async => Right(meals));

      final result = await useCase('user1');
      expect(result.getRight().getOrElse(() => -1), 3);
    });

    test('returns 0 when no meal today', () async {
      final now = DateTime.now();
      final meals = [
        makeMeal(now.subtract(const Duration(days: 1))),
        makeMeal(now.subtract(const Duration(days: 2))),
      ];

      when(() => mockRepo.getMealHistory('user1', limit: 500))
          .thenAnswer((_) async => Right(meals));

      final result = await useCase('user1');
      expect(result.getRight().getOrElse(() => -1), 0);
    });

    test('returns Left on failure', () async {
      when(() => mockRepo.getMealHistory('user1', limit: 500))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase('user1');
      expect(result.isLeft(), true);
    });
  });
}
