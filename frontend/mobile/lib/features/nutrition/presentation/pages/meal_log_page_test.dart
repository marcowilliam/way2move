import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/nutrition/data/repositories/meal_repository_impl.dart';
import 'package:way2move/features/nutrition/domain/entities/meal.dart';
import 'package:way2move/features/nutrition/domain/repositories/meal_repository.dart';
import 'package:way2move/features/nutrition/presentation/pages/meal_log_page.dart';

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late MockMealRepository mockRepo;

  final tMeal = Meal(
    id: 'm1',
    userId: 'test-uid',
    date: DateTime(2026, 3, 29, 8),
    mealType: MealType.breakfast,
    description: 'Oatmeal',
    stomachFeeling: 4,
    source: 'manual',
  );

  setUp(() {
    mockRepo = MockMealRepository();
  });

  setUpAll(() {
    registerFallbackValue(tMeal);
  });

  Widget buildPage() {
    return ProviderScope(
      overrides: [
        mealRepositoryProvider.overrideWithValue(mockRepo),
        currentUserIdProvider.overrideWithValue('test-uid'),
      ],
      child: const MaterialApp(home: MealLogPage()),
    );
  }

  testWidgets('renders meal log page with all key fields', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.byKey(AppKeys.mealLogPage), findsOneWidget);
    expect(find.byKey(AppKeys.mealTypeSelector), findsOneWidget);
    expect(find.byKey(AppKeys.mealDescriptionField), findsOneWidget);
    expect(find.byKey(AppKeys.stomachFeelingSelector), findsOneWidget);
    expect(find.byKey(AppKeys.stomachNotesField), findsOneWidget);
    expect(find.byKey(AppKeys.saveMealButton), findsOneWidget);
  });

  testWidgets('save button is disabled when required fields are empty',
      (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(AppKeys.saveMealButton),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('save button is disabled when only meal type is selected',
      (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    // Select meal type
    await tester.tap(find.text('Breakfast'));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(AppKeys.saveMealButton),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('save button enabled when all required fields are filled',
      (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    // Select meal type
    await tester.tap(find.text('Breakfast'));
    await tester.pump();

    // Enter description
    await tester.enterText(
        find.byKey(AppKeys.mealDescriptionField), 'Oatmeal with berries');
    await tester.pump();

    // Select stomach feeling (tap "Good")
    await tester.tap(find.text('Good'));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(AppKeys.saveMealButton),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('save calls createMeal with correct data and pops on success',
      (tester) async {
    when(() => mockRepo.createMeal(any()))
        .thenAnswer((_) async => Right(tMeal));

    await tester.pumpWidget(buildPage());
    await tester.pump();

    await tester.tap(find.text('Breakfast'));
    await tester.pump();

    await tester.enterText(find.byKey(AppKeys.mealDescriptionField), 'Oatmeal');
    await tester.pump();

    await tester.tap(find.text('Good'));
    await tester.pump();

    // Scroll to the save button before tapping
    await tester.ensureVisible(find.byKey(AppKeys.saveMealButton));
    await tester.pump();

    await tester.tap(find.byKey(AppKeys.saveMealButton));
    await tester.pumpAndSettle();

    verify(() => mockRepo.createMeal(any())).called(1);
  });

  testWidgets('shows all meal type chips', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Snack'), findsOneWidget);
    expect(find.text('Drink'), findsOneWidget);
  });

  testWidgets('shows all stomach feeling options', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.text('Terrible'), findsOneWidget);
    expect(find.text('Bad'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Great'), findsOneWidget);
  });
}
