import 'package:flutter_test/flutter_test.dart';

import '../../../profile/domain/entities/user_profile.dart';
import '../entities/nutrition_target.dart';
import 'calculate_nutrition_target.dart';

void main() {
  late CalculateNutritionTarget useCase;

  setUp(() {
    useCase = const CalculateNutritionTarget();
  });

  UserProfile makeProfile({
    int? age = 30,
    double? weight = 75.0, // kg
    double? height = 175.0, // cm
    ActivityLevel? activityLevel = ActivityLevel.moderatelyActive,
  }) {
    return UserProfile(
      id: 'u1',
      name: 'Test',
      email: 'test@test.com',
      age: age,
      weight: weight,
      height: height,
      activityLevel: activityLevel,
      createdAt: DateTime(2024),
    );
  }

  group('CalculateNutritionTarget', () {
    test('returns null when age is missing', () {
      final result = useCase(
          profile: makeProfile(age: null), preset: MacroPreset.maintenance);
      expect(result, isNull);
    });

    test('returns null when weight is missing', () {
      final result = useCase(
          profile: makeProfile(weight: null), preset: MacroPreset.maintenance);
      expect(result, isNull);
    });

    test('returns null when height is missing', () {
      final result = useCase(
          profile: makeProfile(height: null), preset: MacroPreset.maintenance);
      expect(result, isNull);
    });

    test('returns null when activityLevel is missing', () {
      final result = useCase(
          profile: makeProfile(activityLevel: null),
          preset: MacroPreset.maintenance);
      expect(result, isNull);
    });

    test('returns a NutritionTarget for maintenance preset', () {
      final result =
          useCase(profile: makeProfile(), preset: MacroPreset.maintenance);

      expect(result, isNotNull);
      expect(result!.preset, MacroPreset.maintenance);
      expect(result.userId, 'u1');
      // BMR = 10*75 + 6.25*175 - 5*30 - 78 = 750 + 1093.75 - 150 - 78 = 1615.75
      // TDEE = 1615.75 * 1.55 = 2504.4 (approx)
      expect(result.tdee, closeTo(2504.4, 1.0));
      expect(result.baseCalories, closeTo(2504.4, 1.0)); // maintenance = tdee
    });

    test('fat loss preset applies 20% calorie deficit', () {
      final result =
          useCase(profile: makeProfile(), preset: MacroPreset.fatLoss);

      expect(result, isNotNull);
      // baseCalories ≈ TDEE * 0.80
      expect(result!.baseCalories, closeTo(result.tdee * 0.80, 1.0));
    });

    test('muscle gain preset applies 10% calorie surplus', () {
      final result =
          useCase(profile: makeProfile(), preset: MacroPreset.muscleGain);

      expect(result, isNotNull);
      expect(result!.baseCalories, closeTo(result.tdee * 1.10, 1.0));
    });

    test('training day calories are 15% above base', () {
      final result =
          useCase(profile: makeProfile(), preset: MacroPreset.maintenance);

      expect(result!.trainingDayCalories,
          closeTo(result.baseCalories * 1.15, 1.0));
    });

    test('rest day calories are 10% below base', () {
      final result =
          useCase(profile: makeProfile(), preset: MacroPreset.maintenance);

      expect(result!.restDayCalories, closeTo(result.baseCalories * 0.90, 1.0));
    });

    test('maintenance macro grams match 30/40/30 ratio at 4/4/9 kcal per gram',
        () {
      final result =
          useCase(profile: makeProfile(), preset: MacroPreset.maintenance);

      expect(result, isNotNull);
      final base = result!.baseCalories;
      expect(result.proteinGrams, closeTo(base * 0.30 / 4, 1.0));
      expect(result.carbsGrams, closeTo(base * 0.40 / 4, 1.0));
      expect(result.fatGrams, closeTo(base * 0.30 / 9, 1.0));
    });

    test('fat loss macro grams match 40/30/30 ratio', () {
      final result =
          useCase(profile: makeProfile(), preset: MacroPreset.fatLoss);

      expect(result, isNotNull);
      final base = result!.baseCalories;
      expect(result.proteinGrams, closeTo(base * 0.40 / 4, 1.0));
      expect(result.carbsGrams, closeTo(base * 0.30 / 4, 1.0));
      expect(result.fatGrams, closeTo(base * 0.30 / 9, 1.0));
    });

    test('muscle gain macro grams match 30/50/20 ratio', () {
      final result =
          useCase(profile: makeProfile(), preset: MacroPreset.muscleGain);

      expect(result, isNotNull);
      final base = result!.baseCalories;
      expect(result.proteinGrams, closeTo(base * 0.30 / 4, 1.0));
      expect(result.carbsGrams, closeTo(base * 0.50 / 4, 1.0));
      expect(result.fatGrams, closeTo(base * 0.20 / 9, 1.0));
    });

    test('sedentary activity uses 1.2 multiplier', () {
      final result = useCase(
        profile: makeProfile(activityLevel: ActivityLevel.sedentary),
        preset: MacroPreset.maintenance,
      );
      // BMR for our profile: 10*75 + 6.25*175 - 5*30 - 78 = 1615.75
      expect(result!.tdee, closeTo(1615.75 * 1.2, 1.0));
    });

    test('extremelyActive uses 1.9 multiplier', () {
      final result = useCase(
        profile: makeProfile(activityLevel: ActivityLevel.extremelyActive),
        preset: MacroPreset.maintenance,
      );
      expect(result!.tdee, closeTo(1615.75 * 1.9, 1.0));
    });
  });
}
