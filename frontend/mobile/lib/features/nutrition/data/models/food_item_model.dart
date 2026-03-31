import '../../domain/entities/food_item.dart';

class FoodItemModel {
  final String name;
  final double portionGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodItemModel({
    required this.name,
    required this.portionGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodItemModel.fromMap(Map<String, dynamic> map) => FoodItemModel(
        name: map['name'] as String? ?? '',
        portionGrams: (map['portionGrams'] as num?)?.toDouble() ?? 100,
        calories: (map['calories'] as num?)?.toDouble() ?? 0,
        protein: (map['protein'] as num?)?.toDouble() ?? 0,
        carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
        fat: (map['fat'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'portionGrams': portionGrams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  FoodItem toEntity() => FoodItem(
        name: name,
        portionGrams: portionGrams,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );

  factory FoodItemModel.fromEntity(FoodItem item) => FoodItemModel(
        name: item.name,
        portionGrams: item.portionGrams,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
      );
}
