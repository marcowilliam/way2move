import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/nutrition/domain/repositories/meal_repository.dart';
import 'package:way2move/features/nutrition/domain/usecases/delete_meal.dart';

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late MockMealRepository mockRepo;
  late DeleteMeal deleteMeal;

  setUp(() {
    mockRepo = MockMealRepository();
    deleteMeal = DeleteMeal(mockRepo);
  });

  group('DeleteMeal', () {
    test('returns Unit on success', () async {
      when(() => mockRepo.deleteMeal(any()))
          .thenAnswer((_) async => const Right(unit));

      final result = await deleteMeal('m1');

      expect(result, const Right(unit));
      verify(() => mockRepo.deleteMeal('m1')).called(1);
    });

    test('returns NotFoundFailure when meal does not exist', () async {
      when(() => mockRepo.deleteMeal(any()))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await deleteMeal('nonexistent');

      expect(result, const Left(NotFoundFailure()));
    });

    test('returns ServerFailure on server error', () async {
      when(() => mockRepo.deleteMeal(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await deleteMeal('m1');

      expect(result.isLeft(), true);
    });

    test('passes the mealId to repository', () async {
      when(() => mockRepo.deleteMeal(any()))
          .thenAnswer((_) async => const Right(unit));

      await deleteMeal('meal-xyz');

      verify(() => mockRepo.deleteMeal('meal-xyz')).called(1);
    });
  });
}
