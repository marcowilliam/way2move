class FoodItem {
  final String name;
  final double portionGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodItem({
    required this.name,
    this.portionGrams = 100,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  FoodItem copyWith({
    String? name,
    double? portionGrams,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) =>
      FoodItem(
        name: name ?? this.name,
        portionGrams: portionGrams ?? this.portionGrams,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
      );

  /// Returns macros scaled to the current [portionGrams] relative to a 100g base.
  double get scaledCalories => calories * portionGrams / 100;
  double get scaledProtein => protein * portionGrams / 100;
  double get scaledCarbs => carbs * portionGrams / 100;
  double get scaledFat => fat * portionGrams / 100;

  @override
  bool operator ==(Object other) =>
      other is FoodItem &&
      other.name == name &&
      other.portionGrams == portionGrams;

  @override
  int get hashCode => Object.hash(name, portionGrams);
}
