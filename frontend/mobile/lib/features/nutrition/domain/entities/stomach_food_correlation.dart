class StomachFoodCorrelation {
  final String foodName;
  final double avgStomachFeeling;
  final int occurrences;

  const StomachFoodCorrelation({
    required this.foodName,
    required this.avgStomachFeeling,
    required this.occurrences,
  });

  bool get isProblematic => avgStomachFeeling <= 2.0;

  @override
  bool operator ==(Object other) =>
      other is StomachFoodCorrelation && other.foodName == foodName;

  @override
  int get hashCode => foodName.hashCode;
}
