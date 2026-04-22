import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/nutrition/domain/entities/meal.dart';
import 'package:way2move/features/nutrition/domain/repositories/meal_repository.dart';
import 'package:way2move/features/nutrition/domain/usecases/get_meals_by_date.dart';

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late MockMealRepository mockRepo;
  late GetMealsByDate getMealsByDate;

  final tDate = DateTime(2026, 3, 29);

  final tMeals = [
    Meal(
      id: 'm1',
      userId: 'user1',
      date: DateTime(2026, 3, 29, 8),
      mealType: MealType.breakfast,
      description: 'Oatmeal',
      stomachFeeling: 4,
      origin: 'manual',
    ),
    Meal(
      id: 'm2',
      userId: 'user1',
      date: DateTime(2026, 3, 29, 12),
      mealType: MealType.lunch,
      description: 'Salad',
      stomachFeeling: 3,
      origin: 'manual',
    ),
  ];

  setUp(() {
    mockRepo = MockMealRepository();
    getMealsByDate = GetMealsByDate(mockRepo);
  });

  group('GetMealsByDate', () {
    test('returns list of meals for the given date on success', () async {
      when(() => mockRepo.getMealsByDate(any(), any()))
          .thenAnswer((_) async => Right(tMeals));

      final result = await getMealsByDate('user1', tDate);

      expect(result, Right(tMeals));
      verify(() => mockRepo.getMealsByDate('user1', tDate)).called(1);
    });

    test('returns empty list when no meals for that date', () async {
      when(() => mockRepo.getMealsByDate(any(), any()))
          .thenAnswer((_) async => const Right([]));

      final result = await getMealsByDate('user1', tDate);

      expect(result, const Right<AppFailure, List<Meal>>([]));
    });

    test('returns ServerFailure on repository error', () async {
      when(() => mockRepo.getMealsByDate(any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getMealsByDate('user1', tDate);

      expect(result.isLeft(), true);
    });

    test('passes correct userId and date to repository', () async {
      when(() => mockRepo.getMealsByDate(any(), any()))
          .thenAnswer((_) async => Right(tMeals));

      await getMealsByDate('specific-user', DateTime(2026, 1, 1));

      verify(() =>
              mockRepo.getMealsByDate('specific-user', DateTime(2026, 1, 1)))
          .called(1);
    });
  });
}
