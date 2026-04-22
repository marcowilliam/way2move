import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/nutrition_target.dart';

class NutritionTargetModel {
  final String userId;
  final String preset;
  final double tdee;
  final double baseCalories;
  final double trainingDayCalories;
  final double restDayCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final DateTime updatedAt;
  final String source;
  final String? idempotencyKey;

  const NutritionTargetModel({
    required this.userId,
    required this.preset,
    required this.tdee,
    required this.baseCalories,
    required this.trainingDayCalories,
    required this.restDayCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.updatedAt,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory NutritionTargetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return NutritionTargetModel(
      userId: data['userId'] as String,
      preset: data['preset'] as String,
      tdee: (data['tdee'] as num).toDouble(),
      baseCalories: (data['baseCalories'] as num).toDouble(),
      trainingDayCalories: (data['trainingDayCalories'] as num).toDouble(),
      restDayCalories: (data['restDayCalories'] as num).toDouble(),
      proteinGrams: (data['proteinGrams'] as num).toDouble(),
      carbsGrams: (data['carbsGrams'] as num).toDouble(),
      fatGrams: (data['fatGrams'] as num).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'preset': preset,
        'tdee': tdee,
        'baseCalories': baseCalories,
        'trainingDayCalories': trainingDayCalories,
        'restDayCalories': restDayCalories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'updatedAt': FieldValue.serverTimestamp(),
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  factory NutritionTargetModel.fromEntity(NutritionTarget target) {
    return NutritionTargetModel(
      userId: target.userId,
      preset: target.preset.name,
      tdee: target.tdee,
      baseCalories: target.baseCalories,
      trainingDayCalories: target.trainingDayCalories,
      restDayCalories: target.restDayCalories,
      proteinGrams: target.proteinGrams,
      carbsGrams: target.carbsGrams,
      fatGrams: target.fatGrams,
      updatedAt: target.updatedAt,
    );
  }

  NutritionTarget toEntity() => NutritionTarget(
        userId: userId,
        preset: MacroPreset.values.byName(preset),
        tdee: tdee,
        baseCalories: baseCalories,
        trainingDayCalories: trainingDayCalories,
        restDayCalories: restDayCalories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
        updatedAt: updatedAt,
      );
}
