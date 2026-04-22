import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/exercise.dart';

class ExerciseModel {
  final String id;
  final String name;
  final String description;
  final String videoUrl;
  final List<String> sportTags;
  final List<String> patternTags;
  final List<String> regionTags;
  final List<String> typeTags;
  final List<String> equipmentTags;
  final String difficulty;
  final List<String> progressionIds;
  final List<String> regressionIds;
  final List<String> cues;
  final bool isCustom;
  final String? createdByUserId;
  final String source;
  final String? idempotencyKey;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    this.videoUrl = '',
    this.sportTags = const [],
    this.patternTags = const [],
    this.regionTags = const [],
    this.typeTags = const [],
    this.equipmentTags = const [],
    required this.difficulty,
    this.progressionIds = const [],
    this.regressionIds = const [],
    this.cues = const [],
    this.isCustom = false,
    this.createdByUserId,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return ExerciseModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      sportTags: List<String>.from(data['sportTags'] ?? []),
      patternTags: List<String>.from(data['patternTags'] ?? []),
      regionTags: List<String>.from(data['regionTags'] ?? []),
      typeTags: List<String>.from(data['typeTags'] ?? []),
      equipmentTags: List<String>.from(data['equipmentTags'] ?? []),
      difficulty: data['difficulty'] as String? ?? 'beginner',
      progressionIds: List<String>.from(data['progressionIds'] ?? []),
      regressionIds: List<String>.from(data['regressionIds'] ?? []),
      cues: List<String>.from(data['cues'] ?? []),
      isCustom: data['isCustom'] as bool? ?? false,
      createdByUserId: data['createdByUserId'] as String?,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> data, String id) {
    return ExerciseModel(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      sportTags: List<String>.from(data['sportTags'] ?? []),
      patternTags: List<String>.from(data['patternTags'] ?? []),
      regionTags: List<String>.from(data['regionTags'] ?? []),
      typeTags: List<String>.from(data['typeTags'] ?? []),
      equipmentTags: List<String>.from(data['equipmentTags'] ?? []),
      difficulty: data['difficulty'] as String? ?? 'beginner',
      progressionIds: List<String>.from(data['progressionIds'] ?? []),
      regressionIds: List<String>.from(data['regressionIds'] ?? []),
      cues: List<String>.from(data['cues'] ?? []),
      isCustom: data['isCustom'] as bool? ?? false,
      createdByUserId: data['createdByUserId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'videoUrl': videoUrl,
        'sportTags': sportTags,
        'patternTags': patternTags,
        'regionTags': regionTags,
        'typeTags': typeTags,
        'equipmentTags': equipmentTags,
        'difficulty': difficulty,
        'progressionIds': progressionIds,
        'regressionIds': regressionIds,
        'cues': cues,
        'isCustom': isCustom,
        if (createdByUserId != null) 'createdByUserId': createdByUserId,
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  Exercise toEntity() => Exercise(
        id: id,
        name: name,
        description: description,
        videoUrl: videoUrl,
        sportTags: sportTags
            .map((t) => SportTag.values.firstWhere((e) => e.name == t,
                orElse: () => SportTag.generalFitness))
            .toList(),
        patternTags: patternTags
            .map((t) => MovementPattern.values.firstWhere((e) => e.name == t,
                orElse: () => MovementPattern.squat))
            .toList(),
        regionTags: regionTags
            .map((t) => BodyRegion.values.firstWhere((e) => e.name == t,
                orElse: () => BodyRegion.fullBody))
            .toList(),
        typeTags: typeTags
            .map((t) => ExerciseType.values.firstWhere((e) => e.name == t,
                orElse: () => ExerciseType.corrective))
            .toList(),
        equipmentTags: equipmentTags
            .map((t) => EquipmentTag.values.firstWhere((e) => e.name == t,
                orElse: () => EquipmentTag.bodyweight))
            .toList(),
        difficulty: ExerciseDifficulty.values.firstWhere(
          (e) => e.name == difficulty,
          orElse: () => ExerciseDifficulty.beginner,
        ),
        progressionIds: progressionIds,
        regressionIds: regressionIds,
        cues: cues,
        isCustom: isCustom,
        createdByUserId: createdByUserId,
      );

  factory ExerciseModel.fromEntity(Exercise e) => ExerciseModel(
        id: e.id,
        name: e.name,
        description: e.description,
        videoUrl: e.videoUrl,
        sportTags: e.sportTags.map((t) => t.name).toList(),
        patternTags: e.patternTags.map((t) => t.name).toList(),
        regionTags: e.regionTags.map((t) => t.name).toList(),
        typeTags: e.typeTags.map((t) => t.name).toList(),
        equipmentTags: e.equipmentTags.map((t) => t.name).toList(),
        difficulty: e.difficulty.name,
        progressionIds: e.progressionIds,
        regressionIds: e.regressionIds,
        cues: e.cues,
        isCustom: e.isCustom,
        createdByUserId: e.createdByUserId,
      );
}
