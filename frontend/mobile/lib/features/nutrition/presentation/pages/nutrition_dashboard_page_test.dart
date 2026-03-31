import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/nutrition/data/repositories/meal_repository_impl.dart';
import 'package:way2move/features/nutrition/data/repositories/nutrition_target_repository_impl.dart';
import 'package:way2move/features/nutrition/domain/entities/food_item.dart';
import 'package:way2move/features/nutrition/domain/entities/meal.dart';
import 'package:way2move/features/nutrition/domain/entities/nutrition_target.dart';
import 'package:way2move/features/nutrition/domain/repositories/meal_repository.dart';
import 'package:way2move/features/nutrition/domain/repositories/nutrition_target_repository.dart';
import 'package:way2move/features/nutrition/presentation/pages/nutrition_dashboard_page.dart';
import 'package:way2move/features/nutrition/presentation/widgets/calorie_progress_bar.dart';
import 'package:way2move/features/nutrition/presentation/widgets/macro_ring_chart.dart';
import 'package:way2move/features/nutrition/presentation/widgets/stomach_correlation_list.dart';

class MockMealRepository extends Mock implements MealRepository {}

class MockNutritionTargetRepository extends Mock
    implements NutritionTargetRepository {}

NutritionTarget _target() => NutritionTarget(
      userId: 'u1',
      preset: MacroPreset.maintenance,
      tdee: 2500,
      baseCalories: 2500,
      trainingDayCalories: 2875,
      restDayCalories: 2250,
      proteinGrams: 187,
      carbsGrams: 250,
      fatGrams: 83,
      updatedAt: DateTime(2024),
    );

Meal _makeMeal({
  required DateTime date,
  int stomachFeeling = 3,
  List<FoodItem>? foodItems,
  String description = 'test meal',
}) =>
    Meal(
      id: 'meal-${date.millisecondsSinceEpoch}',
      userId: 'u1',
      date: date,
      mealType: MealType.lunch,
      description: description,
      stomachFeeling: stomachFeeling,
      foodItems: foodItems,
    );

void main() {
  late MockMealRepository mockMealRepo;
  late MockNutritionTargetRepository mockTargetRepo;

  setUp(() {
    mockMealRepo = MockMealRepository();
    mockTargetRepo = MockNutritionTargetRepository();
  });

  Widget buildDashboard() {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        mealRepositoryProvider.overrideWithValue(mockMealRepo),
        nutritionTargetRepositoryProvider.overrideWithValue(mockTargetRepo),
      ],
      child: const MaterialApp(home: NutritionDashboardPage()),
    );
  }

  group('NutritionDashboardPage', () {
    testWidgets('shows section titles', (tester) async {
      when(() => mockMealRepo.getMealsByDateRange(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockMealRepo.getMealHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockTargetRepo.getTarget(any()))
          .thenAnswer((_) async => Right(_target()));

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Weekly Calories'), findsOneWidget);
      expect(find.text('Consistency'), findsOneWidget);
      expect(find.text('Stomach-Food Correlations'), findsOneWidget);
      expect(find.text('Quick Add from History'), findsOneWidget);
    });

    testWidgets('shows consistency stats', (tester) async {
      final now = DateTime.now();
      final meals = [
        _makeMeal(date: now),
        _makeMeal(date: now.subtract(const Duration(days: 1))),
      ];

      when(() => mockMealRepo.getMealsByDateRange(any(), any(), any()))
          .thenAnswer((_) async => Right(meals));
      when(() => mockMealRepo.getMealHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(meals));
      when(() => mockTargetRepo.getTarget(any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Days logged this week'), findsOneWidget);
      expect(find.text('Day streak'), findsOneWidget);
    });

    testWidgets('shows empty state for correlations when no data',
        (tester) async {
      when(() => mockMealRepo.getMealsByDateRange(any(), any(), any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockMealRepo.getMealHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Right([]));
      when(() => mockTargetRepo.getTarget(any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.textContaining('Not enough data'), findsOneWidget);
    });
  });

  group('MacroRingChart', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MacroRingChart(
              label: 'Protein',
              value: 100,
              target: 187,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('/ 187g'), findsOneWidget);
    });
  });

  group('CalorieProgressBar', () {
    testWidgets('renders consumed and target values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalorieProgressBar(consumed: 1800, target: 2500),
          ),
        ),
      );

      expect(find.text('1800 kcal'), findsOneWidget);
      expect(find.text('/ 2500 kcal'), findsOneWidget);
    });
  });

  group('StomachCorrelationList', () {
    testWidgets('shows empty state when no correlations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StomachCorrelationList(correlations: []),
          ),
        ),
      );

      expect(find.textContaining('Not enough data'), findsOneWidget);
    });
  });
}
