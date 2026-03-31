import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/nutrition/domain/entities/food_item.dart';

void main() {
  const tItem = FoodItem(
    name: 'Chicken Breast',
    portionGrams: 100,
    calories: 165,
    protein: 31,
    carbs: 0,
    fat: 3.6,
  );

  group('FoodItem equality', () {
    test('two items with same name and portionGrams are equal', () {
      const a = FoodItem(
        name: 'Chicken Breast',
        portionGrams: 100,
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      );
      const b = FoodItem(
        name: 'Chicken Breast',
        portionGrams: 100,
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      );
      expect(a, equals(b));
    });

    test('items with different portionGrams are not equal', () {
      const a = FoodItem(
        name: 'Chicken Breast',
        portionGrams: 100,
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      );
      const b = FoodItem(
        name: 'Chicken Breast',
        portionGrams: 200,
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      );
      expect(a, isNot(equals(b)));
    });

    test('items with different names are not equal', () {
      const a = FoodItem(
        name: 'Chicken Breast',
        portionGrams: 100,
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      );
      const b = FoodItem(
        name: 'Turkey Breast',
        portionGrams: 100,
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('FoodItem copyWith', () {
    test('copyWith creates new instance with updated fields', () {
      final updated = tItem.copyWith(portionGrams: 150, calories: 200);
      expect(updated.portionGrams, 150);
      expect(updated.calories, 200);
      expect(updated.name, tItem.name);
      expect(updated.protein, tItem.protein);
    });

    test('copyWith without args returns equivalent item', () {
      final copy = tItem.copyWith();
      expect(copy, equals(tItem));
    });
  });

  group('FoodItem scaled nutrition', () {
    test('scaledCalories at 100g equals base calories', () {
      expect(tItem.scaledCalories, closeTo(165, 0.001));
    });

    test('scaledCalories at 200g is double the base', () {
      final big = tItem.copyWith(portionGrams: 200);
      expect(big.scaledCalories, closeTo(330, 0.001));
    });

    test('scaledProtein scales proportionally', () {
      final half = tItem.copyWith(portionGrams: 50);
      expect(half.scaledProtein, closeTo(15.5, 0.001));
    });

    test('scaledFat scales proportionally', () {
      final double = tItem.copyWith(portionGrams: 200);
      expect(double.scaledFat, closeTo(7.2, 0.001));
    });

    test('default portionGrams is 100', () {
      const item = FoodItem(
        name: 'Test',
        calories: 100,
        protein: 10,
        carbs: 10,
        fat: 5,
      );
      expect(item.portionGrams, 100);
    });
  });
}
