import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/nutrition/domain/entities/meal.dart';
import 'package:way2move/features/nutrition/domain/repositories/meal_repository.dart';
import 'package:way2move/features/nutrition/domain/usecases/create_meal.dart';

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late MockMealRepository mockRepo;
  late CreateMeal createMeal;

  final tMeal = Meal(
    id: 'm1',
    userId: 'user1',
    date: DateTime(2026, 3, 29, 8),
    mealType: MealType.breakfast,
    description: 'Oatmeal with berries',
    stomachFeeling: 4,
    source: 'manual',
  );

  setUp(() {
    mockRepo = MockMealRepository();
    createMeal = CreateMeal(mockRepo);
    registerFallbackValue(tMeal);
  });

  group('CreateMeal', () {
    test('returns Meal on success', () async {
      when(() => mockRepo.createMeal(any()))
          .thenAnswer((_) async => Right(tMeal));

      final result = await createMeal(tMeal);

      expect(result, Right(tMeal));
      verify(() => mockRepo.createMeal(tMeal)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.createMeal(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await createMeal(tMeal);

      expect(result.isLeft(), true);
      expect(result, const Left(ServerFailure()));
    });

    test('calls repository exactly once', () async {
      when(() => mockRepo.createMeal(any()))
          .thenAnswer((_) async => Right(tMeal));

      await createMeal(tMeal);

      verify(() => mockRepo.createMeal(any())).called(1);
      verifyNoMoreInteractions(mockRepo);
    });
  });
}
