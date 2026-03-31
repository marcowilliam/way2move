import '../entities/nutrition_target.dart';
import '../../../profile/domain/entities/user_profile.dart';

/// Calculates a NutritionTarget from a UserProfile using the
/// Mifflin-St Jeor BMR formula (gender-neutral average) × activity multiplier.
///
/// Returns null if the profile is missing required fields
/// (age, weight, height, activityLevel).
class CalculateNutritionTarget {
  const CalculateNutritionTarget();

  NutritionTarget? call({
    required UserProfile profile,
    required MacroPreset preset,
  }) {
    final age = profile.age;
    final weight = profile.weight; // kg
    final height = profile.height; // cm
    final activityLevel = profile.activityLevel;

    if (age == null ||
        weight == null ||
        height == null ||
        activityLevel == null) {
      return null;
    }

    // Mifflin-St Jeor (gender-neutral average of male +5 / female -161 = -78)
    final bmr = 10 * weight + 6.25 * height - 5 * age - 78;

    final activityMultiplier = _activityMultiplier(activityLevel);
    final tdee = bmr * activityMultiplier;

    // Calorie adjustment per preset
    final baseCalories = switch (preset) {
      MacroPreset.fatLoss => tdee * 0.80, // -20% deficit
      MacroPreset.maintenance => tdee,
      MacroPreset.muscleGain => tdee * 1.10, // +10% surplus
    };

    final trainingDayCalories = baseCalories * 1.15;
    final restDayCalories = baseCalories * 0.90;

    // Macro grams from preset ratios
    // Protein & carbs = 4 kcal/g, fat = 9 kcal/g
    final (proteinRatio, carbsRatio, fatRatio) = preset.macroRatios;
    final proteinGrams = baseCalories * proteinRatio / 4;
    final carbsGrams = baseCalories * carbsRatio / 4;
    final fatGrams = baseCalories * fatRatio / 9;

    return NutritionTarget(
      userId: profile.id,
      preset: preset,
      tdee: _round(tdee),
      baseCalories: _round(baseCalories),
      trainingDayCalories: _round(trainingDayCalories),
      restDayCalories: _round(restDayCalories),
      proteinGrams: _round(proteinGrams),
      carbsGrams: _round(carbsGrams),
      fatGrams: _round(fatGrams),
      updatedAt: DateTime.now(),
    );
  }

  double _activityMultiplier(ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => 1.2,
      ActivityLevel.lightlyActive => 1.375,
      ActivityLevel.moderatelyActive => 1.55,
      ActivityLevel.veryActive => 1.725,
      ActivityLevel.extremelyActive => 1.9,
    };
  }

  double _round(double value) => (value * 10).round() / 10;
}
