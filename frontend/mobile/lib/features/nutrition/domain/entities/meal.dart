import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snack, drink }

class Meal {
  final String id;
  final String userId;
  final DateTime date;
  final MealType mealType;
  final String description;
  final int stomachFeeling; // 1–5
  final String? stomachNotes;
  final String source; // 'manual' | 'voice'
  final String? linkedJournalId;

  // Macro tracking fields (nullable for backwards compatibility)
  final List<FoodItem>? foodItems;
  final double? calories; // manual override; falls back to sum of foodItems
  final double? protein;
  final double? carbs;
  final double? fat;

  const Meal({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.description,
    required this.stomachFeeling,
    this.stomachNotes,
    this.source = 'manual',
    this.linkedJournalId,
    this.foodItems,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  bool get hasMacros => foodItems != null && foodItems!.isNotEmpty;

  double get totalCalories =>
      calories ??
      foodItems?.fold(0.0, (s, i) => (s ?? 0) + i.scaledCalories) ??
      0;

  double get totalProtein =>
      protein ??
      foodItems?.fold(0.0, (s, i) => (s ?? 0) + i.scaledProtein) ??
      0;

  double get totalCarbs =>
      carbs ?? foodItems?.fold(0.0, (s, i) => (s ?? 0) + i.scaledCarbs) ?? 0;

  double get totalFat =>
      fat ?? foodItems?.fold(0.0, (s, i) => (s ?? 0) + i.scaledFat) ?? 0;

  Meal copyWith({
    String? id,
    String? userId,
    DateTime? date,
    MealType? mealType,
    String? description,
    int? stomachFeeling,
    String? stomachNotes,
    String? source,
    String? linkedJournalId,
    List<FoodItem>? foodItems,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) =>
      Meal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        date: date ?? this.date,
        mealType: mealType ?? this.mealType,
        description: description ?? this.description,
        stomachFeeling: stomachFeeling ?? this.stomachFeeling,
        stomachNotes: stomachNotes ?? this.stomachNotes,
        source: source ?? this.source,
        linkedJournalId: linkedJournalId ?? this.linkedJournalId,
        foodItems: foodItems ?? this.foodItems,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
      );

  @override
  bool operator ==(Object other) => other is Meal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
