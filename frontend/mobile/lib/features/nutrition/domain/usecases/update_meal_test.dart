import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/nutrition/domain/entities/meal.dart';
import 'package:way2move/features/nutrition/domain/repositories/meal_repository.dart';
import 'package:way2move/features/nutrition/domain/usecases/update_meal.dart';

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late MockMealRepository mockRepo;
  late UpdateMeal updateMeal;

  final tMeal = Meal(
    id: 'm1',
    userId: 'user1',
    date: DateTime(2026, 3, 29, 12),
    mealType: MealType.lunch,
    description: 'Salad with chicken',
    stomachFeeling: 3,
    stomachNotes: 'Slight bloating',
    origin: 'manual',
  );

  setUp(() {
    mockRepo = MockMealRepository();
    updateMeal = UpdateMeal(mockRepo);
    registerFallbackValue(tMeal);
  });

  group('UpdateMeal', () {
    test('returns updated Meal on success', () async {
      when(() => mockRepo.updateMeal(any()))
          .thenAnswer((_) async => Right(tMeal));

      final result = await updateMeal(tMeal);

      expect(result, Right(tMeal));
      verify(() => mockRepo.updateMeal(tMeal)).called(1);
    });

    test('returns NotFoundFailure when meal does not exist', () async {
      when(() => mockRepo.updateMeal(any()))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await updateMeal(tMeal);

      expect(result, const Left(NotFoundFailure()));
    });

    test('returns ServerFailure on server error', () async {
      when(() => mockRepo.updateMeal(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await updateMeal(tMeal);

      expect(result.isLeft(), true);
    });
  });
}
