import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/nutrition/data/repositories/nutrition_target_repository_impl.dart';
import 'package:way2move/features/nutrition/domain/entities/nutrition_target.dart';
import 'package:way2move/features/nutrition/domain/repositories/nutrition_target_repository.dart';
import 'package:way2move/features/nutrition/presentation/pages/nutrition_target_settings_page.dart';
import 'package:way2move/features/profile/domain/entities/user_profile.dart';
import 'package:way2move/features/profile/presentation/providers/profile_provider.dart';

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

UserProfile _profile() => UserProfile(
      id: 'u1',
      name: 'Test User',
      email: 'test@test.com',
      age: 30,
      weight: 75,
      height: 175,
      activityLevel: ActivityLevel.moderatelyActive,
      createdAt: DateTime(2024),
    );

void main() {
  late MockNutritionTargetRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(_target());
  });

  setUp(() {
    mockRepo = MockNutritionTargetRepository();
  });

  Widget buildPage({
    NutritionTarget? existingTarget,
    UserProfile? profile,
  }) {
    when(() => mockRepo.getTarget(any()))
        .thenAnswer((_) async => Right(existingTarget));
    when(() => mockRepo.saveTarget(any()))
        .thenAnswer((_) async => Right(_target()));

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        nutritionTargetRepositoryProvider.overrideWithValue(mockRepo),
        profileStreamProvider.overrideWith(
          (ref) => Stream.value(profile ?? _profile()),
        ),
      ],
      child: const MaterialApp(home: NutritionTargetSettingsPage()),
    );
  }

  group('NutritionTargetSettingsPage', () {
    testWidgets('shows all three macro preset cards', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Fat Loss'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('Muscle Gain'), findsOneWidget);
    });

    testWidgets('shows apply button', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('applyTargetButton')), findsOneWidget);
    });

    testWidgets('shows existing target summary when target is saved',
        (tester) async {
      await tester.pumpWidget(buildPage(existingTarget: _target()));
      await tester.pumpAndSettle();

      expect(find.text('Current targets'), findsOneWidget);
      expect(find.text('2500 kcal'), findsOneWidget);
      expect(find.text('187g'), findsOneWidget); // protein
    });

    testWidgets('shows profile warning when profile is incomplete',
        (tester) async {
      final incompleteProfile = UserProfile(
        id: 'u1',
        name: 'Test',
        email: 'test@test.com',
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(buildPage(profile: incompleteProfile));
      await tester.pumpAndSettle();

      expect(find.text('Choose your goal'), findsNothing);
      expect(find.textContaining('Complete your profile'), findsOneWidget);
    });

    testWidgets('tapping a preset card selects it', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fat Loss'));
      await tester.pumpAndSettle();

      // After tapping, the card should show the selected state (check icon)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping apply button calls save and shows success snackbar',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Select a preset first
      await tester.tap(find.text('Maintenance'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('applyTargetButton')));
      await tester.pumpAndSettle();

      expect(find.text('Targets updated'), findsOneWidget);
      verify(() => mockRepo.saveTarget(any())).called(1);
    });

    testWidgets(
        'shows training day and rest day calorie cards for saved target',
        (tester) async {
      await tester.pumpWidget(buildPage(existingTarget: _target()));
      await tester.pumpAndSettle();

      expect(find.text('Training day'), findsOneWidget);
      expect(find.text('Rest day'), findsOneWidget);
    });
  });
}
