import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/goal.dart';

class GoalModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final GoalCategory category;
  final String targetMetric;
  final double targetValue;
  final double currentValue;
  final String unit;
  final String? sport;
  final List<String> compensationIds;
  final List<String> exerciseIds;
  final GoalSource source;
  final GoalStatus status;
  final DateTime? achievedAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.targetMetric,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    this.sport,
    required this.compensationIds,
    required this.exerciseIds,
    required this.source,
    required this.status,
    this.achievedAt,
  });

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      description: (data['description'] as String?) ?? '',
      category: _parseCategory(data['category'] as String),
      targetMetric: data['targetMetric'] as String,
      targetValue: (data['targetValue'] as num).toDouble(),
      currentValue: (data['currentValue'] as num? ?? 0).toDouble(),
      unit: data['unit'] as String,
      sport: data['sport'] as String?,
      compensationIds: List<String>.from(data['compensationIds'] ?? []),
      exerciseIds: List<String>.from(data['exerciseIds'] ?? []),
      source: _parseSource(data['source'] as String),
      status: _parseStatus(data['status'] as String),
      achievedAt: data['achievedAt'] != null
          ? (data['achievedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'description': description,
        'category': category.name,
        'targetMetric': targetMetric,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'unit': unit,
        'sport': sport,
        'compensationIds': compensationIds,
        'exerciseIds': exerciseIds,
        'source': source.name,
        'status': status.name,
        'achievedAt':
            achievedAt != null ? Timestamp.fromDate(achievedAt!) : null,
        'meta': {
          'updatedAt': FieldValue.serverTimestamp(),
        },
        '_schemaVersion': 1,
      };

  Goal toEntity() => Goal(
        id: id,
        userId: userId,
        name: name,
        description: description,
        category: category,
        targetMetric: targetMetric,
        targetValue: targetValue,
        currentValue: currentValue,
        unit: unit,
        sport: sport,
        compensationIds: compensationIds,
        exerciseIds: exerciseIds,
        source: source,
        status: status,
        achievedAt: achievedAt,
      );

  factory GoalModel.fromEntity(Goal entity) => GoalModel(
        id: entity.id,
        userId: entity.userId,
        name: entity.name,
        description: entity.description,
        category: entity.category,
        targetMetric: entity.targetMetric,
        targetValue: entity.targetValue,
        currentValue: entity.currentValue,
        unit: entity.unit,
        sport: entity.sport,
        compensationIds: entity.compensationIds,
        exerciseIds: entity.exerciseIds,
        source: entity.source,
        status: entity.status,
        achievedAt: entity.achievedAt,
      );
}

GoalCategory _parseCategory(String s) => GoalCategory.values
    .firstWhere((e) => e.name == s, orElse: () => GoalCategory.general);

GoalSource _parseSource(String s) => GoalSource.values
    .firstWhere((e) => e.name == s, orElse: () => GoalSource.manual);

GoalStatus _parseStatus(String s) => GoalStatus.values
    .firstWhere((e) => e.name == s, orElse: () => GoalStatus.active);
