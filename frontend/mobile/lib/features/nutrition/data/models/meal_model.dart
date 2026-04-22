import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/meal.dart';
import 'food_item_model.dart';

class MealModel {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType;
  final String description;
  final int stomachFeeling;
  final String? stomachNotes;
  final String origin;
  final String? linkedJournalId;
  final List<FoodItemModel>? foodItems;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String source;
  final String? idempotencyKey;

  const MealModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.description,
    required this.stomachFeeling,
    this.stomachNotes,
    required this.origin,
    this.linkedJournalId,
    this.foodItems,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);

    List<FoodItemModel>? foodItems;
    final rawItems = data['foodItems'];
    if (rawItems is List) {
      foodItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map(FoodItemModel.fromMap)
          .toList();
    }

    return MealModel(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      mealType: data['mealType'] as String? ?? 'snack',
      description: data['description'] as String? ?? '',
      stomachFeeling: (data['stomachFeeling'] as num?)?.toInt() ?? 3,
      stomachNotes: data['stomachNotes'] as String?,
      origin: data['origin'] as String? ?? 'manual',
      linkedJournalId: data['linkedJournalId'] as String?,
      foodItems: foodItems,
      calories: (data['calories'] as num?)?.toDouble(),
      protein: (data['protein'] as num?)?.toDouble(),
      carbs: (data['carbs'] as num?)?.toDouble(),
      fat: (data['fat'] as num?)?.toDouble(),
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'mealType': mealType,
        'description': description,
        'stomachFeeling': stomachFeeling,
        if (stomachNotes != null) 'stomachNotes': stomachNotes,
        'origin': origin,
        if (linkedJournalId != null) 'linkedJournalId': linkedJournalId,
        if (foodItems != null && foodItems!.isNotEmpty)
          'foodItems': foodItems!.map((i) => i.toMap()).toList(),
        if (calories != null) 'calories': calories,
        if (protein != null) 'protein': protein,
        if (carbs != null) 'carbs': carbs,
        if (fat != null) 'fat': fat,
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  Meal toEntity() => Meal(
        id: id,
        userId: userId,
        date: date,
        mealType: _mealTypeFromString(mealType),
        description: description,
        stomachFeeling: stomachFeeling,
        stomachNotes: stomachNotes,
        origin: origin,
        linkedJournalId: linkedJournalId,
        foodItems: foodItems?.map((m) => m.toEntity()).toList(),
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );

  factory MealModel.fromEntity(Meal meal) => MealModel(
        id: meal.id,
        userId: meal.userId,
        date: meal.date,
        mealType: _mealTypeToString(meal.mealType),
        description: meal.description,
        stomachFeeling: meal.stomachFeeling,
        stomachNotes: meal.stomachNotes,
        origin: meal.origin,
        linkedJournalId: meal.linkedJournalId,
        foodItems: meal.foodItems?.map(FoodItemModel.fromEntity).toList(),
        calories: meal.calories,
        protein: meal.protein,
        carbs: meal.carbs,
        fat: meal.fat,
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
