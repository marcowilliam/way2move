enum MacroPreset {
  fatLoss,
  maintenance,
  muscleGain,
}

extension MacroPresetExtension on MacroPreset {
  String get label {
    switch (this) {
      case MacroPreset.fatLoss:
        return 'Fat Loss';
      case MacroPreset.maintenance:
        return 'Maintenance';
      case MacroPreset.muscleGain:
        return 'Muscle Gain';
    }
  }

  // Protein / carbs / fat percentages
  (double, double, double) get macroRatios {
    switch (this) {
      case MacroPreset.fatLoss:
        return (0.40, 0.30, 0.30);
      case MacroPreset.maintenance:
        return (0.30, 0.40, 0.30);
      case MacroPreset.muscleGain:
        return (0.30, 0.50, 0.20);
    }
  }

  String get description {
    switch (this) {
      case MacroPreset.fatLoss:
        return 'High protein, moderate fat & carbs';
      case MacroPreset.maintenance:
        return 'Balanced macros for steady energy';
      case MacroPreset.muscleGain:
        return 'High carbs for performance & growth';
    }
  }
}

class NutritionTarget {
  final String userId;
  final MacroPreset preset;
  final double tdee; // total daily energy expenditure (maintenance calories)
  final double baseCalories; // calories for goal (may differ from TDEE)
  final double trainingDayCalories; // +15% on training days
  final double restDayCalories; // -10% on rest days
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final DateTime updatedAt;

  const NutritionTarget({
    required this.userId,
    required this.preset,
    required this.tdee,
    required this.baseCalories,
    required this.trainingDayCalories,
    required this.restDayCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.updatedAt,
  });

  NutritionTarget copyWith({
    String? userId,
    MacroPreset? preset,
    double? tdee,
    double? baseCalories,
    double? trainingDayCalories,
    double? restDayCalories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    DateTime? updatedAt,
  }) {
    return NutritionTarget(
      userId: userId ?? this.userId,
      preset: preset ?? this.preset,
      tdee: tdee ?? this.tdee,
      baseCalories: baseCalories ?? this.baseCalories,
      trainingDayCalories: trainingDayCalories ?? this.trainingDayCalories,
      restDayCalories: restDayCalories ?? this.restDayCalories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NutritionTarget && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}
