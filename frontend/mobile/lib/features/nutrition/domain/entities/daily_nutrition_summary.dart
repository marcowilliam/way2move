class DailyNutritionSummary {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int mealCount;
  final double avgStomachFeeling;

  const DailyNutritionSummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealCount,
    required this.avgStomachFeeling,
  });

  bool get hasData => mealCount > 0;

  @override
  bool operator ==(Object other) =>
      other is DailyNutritionSummary &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day;

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day);
}
