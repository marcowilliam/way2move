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
  });

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
      );

  @override
  bool operator ==(Object other) => other is Meal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
