enum WeightUnit { kg, lbs }

class WeightLog {
  final String id;
  final String userId;
  final DateTime date;
  final double weight;
  final WeightUnit unit;
  final String? notes;

  const WeightLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    required this.unit,
    this.notes,
  });

  WeightLog copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    WeightUnit? unit,
    String? notes,
  }) {
    return WeightLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          date == other.date &&
          weight == other.weight &&
          unit == other.unit &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(id, userId, date, weight, unit, notes);
}
