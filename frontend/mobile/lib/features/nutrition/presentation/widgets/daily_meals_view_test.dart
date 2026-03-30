import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/nutrition/data/repositories/meal_repository_impl.dart';
import 'package:way2move/features/nutrition/domain/entities/meal.dart';
import 'package:way2move/features/nutrition/domain/repositories/meal_repository.dart';
import 'package:way2move/features/nutrition/presentation/widgets/daily_meals_view.dart';

class MockMealRepository extends Mock implements MealRepository {}

Meal _meal({
  required String id,
  required MealType type,
  String description = 'Test food',
  int feeling = 3,
}) =>
    Meal(
      id: id,
      userId: 'user1',
      date: DateTime(2026, 3, 29, 8),
      mealType: type,
      description: description,
      stomachFeeling: feeling,
      source: 'manual',
    );

Widget _buildWidget(List<Meal> meals, MockMealRepository mockRepo) {
  return ProviderScope(
    overrides: [
      mealRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('user1'),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: DailyMealsView(meals: meals),
      ),
    ),
  );
}

void main() {
  late MockMealRepository mockRepo;

  final tMeal = _meal(id: 'm1', type: MealType.breakfast);

  setUp(() {
    mockRepo = MockMealRepository();
  });

  setUpAll(() {
    registerFallbackValue(tMeal);
  });

  testWidgets('shows empty state for each meal type when no meals',
      (tester) async {
    await tester.pumpWidget(_buildWidget([], mockRepo));
    await tester.pump();

    expect(find.text('No breakfast logged yet'), findsOneWidget);
    expect(find.text('No lunch logged yet'), findsOneWidget);
    expect(find.text('No dinner logged yet'), findsOneWidget);
    expect(find.text('No snack logged yet'), findsOneWidget);
    expect(find.text('No drink logged yet'), findsOneWidget);
  });

  testWidgets('renders meal description when meals are present',
      (tester) async {
    final meals = [
      _meal(id: 'm1', type: MealType.breakfast, description: 'Oatmeal'),
      _meal(id: 'm2', type: MealType.lunch, description: 'Chicken salad'),
    ];

    await tester.pumpWidget(_buildWidget(meals, mockRepo));
    await tester.pump();

    expect(find.text('Oatmeal'), findsOneWidget);
    expect(find.text('Chicken salad'), findsOneWidget);
  });

  testWidgets('groups meals by meal type sections', (tester) async {
    final meals = [
      _meal(id: 'm1', type: MealType.breakfast, description: 'Eggs'),
      _meal(id: 'm2', type: MealType.dinner, description: 'Steak'),
    ];

    await tester.pumpWidget(_buildWidget(meals, mockRepo));
    await tester.pump();

    expect(find.text('BREAKFAST'), findsOneWidget);
    expect(find.text('LUNCH'), findsOneWidget);
    expect(find.text('DINNER'), findsOneWidget);
    expect(find.text('SNACK'), findsOneWidget);
    expect(find.text('DRINK'), findsOneWidget);

    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('No lunch logged yet'), findsOneWidget);
    expect(find.text('Steak'), findsOneWidget);
  });

  testWidgets('shows stomach feeling emoji on meal cards', (tester) async {
    final meals = [
      _meal(id: 'm1', type: MealType.breakfast, feeling: 4),
    ];

    await tester.pumpWidget(_buildWidget(meals, mockRepo));
    await tester.pump();

    expect(find.text('🙂'), findsOneWidget);
  });

  testWidgets('meal cards are dismissible (swipe to delete)', (tester) async {
    when(() => mockRepo.deleteMeal(any()))
        .thenAnswer((_) async => const Right(unit));

    final meals = [
      _meal(id: 'm1', type: MealType.breakfast, description: 'Eggs'),
    ];

    await tester.pumpWidget(_buildWidget(meals, mockRepo));
    await tester.pump();

    await tester.drag(find.byKey(const Key('meal_m1')), const Offset(-500, 0));
    await tester.pumpAndSettle();

    verify(() => mockRepo.deleteMeal('m1')).called(1);
  });
}
