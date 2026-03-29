enum ExerciseDifficulty { beginner, intermediate, advanced }

enum ExerciseType { mobility, stability, strength, breathing, corrective, activation }

enum MovementPattern { hinge, squat, push, pull, rotate, carry, gait }

enum BodyRegion { neck, shoulder, thoracic, lumbar, hip, knee, ankle, fullBody, core }

enum SportTag { running, cycling, swimming, lifting, yoga, generalFitness, teamSport }

enum EquipmentTag { bodyweight, band, foam, ball, barbell, dumbbell, kettlebell, bench }

class Exercise {
  final String id;
  final String name;
  final String description;
  final String videoUrl;
  final List<SportTag> sportTags;
  final List<MovementPattern> patternTags;
  final List<BodyRegion> regionTags;
  final List<ExerciseType> typeTags;
  final List<EquipmentTag> equipmentTags;
  final ExerciseDifficulty difficulty;
  final List<String> progressionIds;
  final List<String> regressionIds;
  final List<String> cues;
  final bool isCustom;
  final String? createdByUserId;

  const Exercise({
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
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? videoUrl,
    List<SportTag>? sportTags,
    List<MovementPattern>? patternTags,
    List<BodyRegion>? regionTags,
    List<ExerciseType>? typeTags,
    List<EquipmentTag>? equipmentTags,
    ExerciseDifficulty? difficulty,
    List<String>? progressionIds,
    List<String>? regressionIds,
    List<String>? cues,
    bool? isCustom,
    String? createdByUserId,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      sportTags: sportTags ?? this.sportTags,
      patternTags: patternTags ?? this.patternTags,
      regionTags: regionTags ?? this.regionTags,
      typeTags: typeTags ?? this.typeTags,
      equipmentTags: equipmentTags ?? this.equipmentTags,
      difficulty: difficulty ?? this.difficulty,
      progressionIds: progressionIds ?? this.progressionIds,
      regressionIds: regressionIds ?? this.regressionIds,
      cues: cues ?? this.cues,
      isCustom: isCustom ?? this.isCustom,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }

  @override
  bool operator ==(Object other) => other is Exercise && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
