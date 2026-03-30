import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/meal.dart';

class MealModel {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType;
  final String description;
  final int stomachFeeling;
  final String? stomachNotes;
  final String source;
  final String? linkedJournalId;

  const MealModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.description,
    required this.stomachFeeling,
    this.stomachNotes,
    required this.source,
    this.linkedJournalId,
  });

  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealModel(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      mealType: data['mealType'] as String? ?? 'snack',
      description: data['description'] as String? ?? '',
      stomachFeeling: (data['stomachFeeling'] as num?)?.toInt() ?? 3,
      stomachNotes: data['stomachNotes'] as String?,
      source: data['source'] as String? ?? 'manual',
      linkedJournalId: data['linkedJournalId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'mealType': mealType,
        'description': description,
        'stomachFeeling': stomachFeeling,
        if (stomachNotes != null) 'stomachNotes': stomachNotes,
        'source': source,
        if (linkedJournalId != null) 'linkedJournalId': linkedJournalId,
      };

  Meal toEntity() => Meal(
        id: id,
        userId: userId,
        date: date,
        mealType: _mealTypeFromString(mealType),
        description: description,
        stomachFeeling: stomachFeeling,
        stomachNotes: stomachNotes,
        source: source,
        linkedJournalId: linkedJournalId,
      );

  factory MealModel.fromEntity(Meal meal) => MealModel(
        id: meal.id,
        userId: meal.userId,
        date: meal.date,
        mealType: _mealTypeToString(meal.mealType),
        description: meal.description,
        stomachFeeling: meal.stomachFeeling,
        stomachNotes: meal.stomachNotes,
        source: meal.source,
        linkedJournalId: meal.linkedJournalId,
      );

  static MealType _mealTypeFromString(String s) => switch (s) {
        'breakfast' => MealType.breakfast,
        'lunch' => MealType.lunch,
        'dinner' => MealType.dinner,
        'drink' => MealType.drink,
        _ => MealType.snack,
      };

  static String _mealTypeToString(MealType t) => switch (t) {
        MealType.breakfast => 'breakfast',
        MealType.lunch => 'lunch',
        MealType.dinner => 'dinner',
        MealType.snack => 'snack',
        MealType.drink => 'drink',
      };
}
