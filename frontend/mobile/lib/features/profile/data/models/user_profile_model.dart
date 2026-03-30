import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

class InjuryModel {
  final String bodyRegion;
  final String description;
  final String severity;
  final bool isActive;

  const InjuryModel({
    required this.bodyRegion,
    required this.description,
    required this.severity,
    required this.isActive,
  });

  factory InjuryModel.fromMap(Map<String, dynamic> map) {
    return InjuryModel(
      bodyRegion: map['bodyRegion'] as String? ?? '',
      description: map['description'] as String? ?? '',
      severity: map['severity'] as String? ?? 'minor',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'bodyRegion': bodyRegion,
        'description': description,
        'severity': severity,
        'isActive': isActive,
      };

  Injury toEntity() => Injury(
        bodyRegion: bodyRegion,
        description: description,
        severity: _parseSeverity(severity),
        isActive: isActive,
      );

  factory InjuryModel.fromEntity(Injury injury) => InjuryModel(
        bodyRegion: injury.bodyRegion,
        description: injury.description,
        severity: injury.severity.name,
        isActive: injury.isActive,
      );

  static InjurySeverity _parseSeverity(String value) {
    return InjurySeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InjurySeverity.minor,
    );
  }
}

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String? trainingGoal;
  final List<String> sportsTags;
  final int? trainingDaysPerWeek;
  final List<String> availableEquipment;
  final List<InjuryModel> injuries;
  final bool onboardingComplete;
  final DateTime createdAt;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.trainingGoal,
    this.sportsTags = const [],
    this.trainingDaysPerWeek,
    this.availableEquipment = const [],
    this.injuries = const [],
    this.onboardingComplete = false,
    required this.createdAt,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfileModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      age: data['age'] as int?,
      height: (data['height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      activityLevel: data['activityLevel'] as String?,
      trainingGoal: data['trainingGoal'] as String?,
      sportsTags: List<String>.from(data['sportsTags'] ?? []),
      trainingDaysPerWeek: data['trainingDaysPerWeek'] as int?,
      availableEquipment: List<String>.from(data['availableEquipment'] ?? []),
      injuries: (data['injuries'] as List<dynamic>?)
              ?.map((e) => InjuryModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      createdAt: data['meta'] != null &&
              (data['meta'] as Map<String, dynamic>)['createdAt'] != null
          ? ((data['meta'] as Map<String, dynamic>)['createdAt'] as Timestamp)
              .toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'avatarUrl': avatarUrl,
        'age': age,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
        'trainingGoal': trainingGoal,
        'sportsTags': sportsTags,
        'trainingDaysPerWeek': trainingDaysPerWeek,
        'availableEquipment': availableEquipment,
        'injuries': injuries.map((i) => i.toMap()).toList(),
        'onboardingComplete': onboardingComplete,
        'meta': {
          'updatedAt': FieldValue.serverTimestamp(),
        },
      };

  UserProfile toEntity() => UserProfile(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        age: age,
        height: height,
        weight: weight,
        activityLevel: _parseActivityLevel(activityLevel),
        trainingGoal: _parseTrainingGoal(trainingGoal),
        sportsTags: sportsTags,
        trainingDaysPerWeek: trainingDaysPerWeek,
        availableEquipment: availableEquipment,
        injuries: injuries.map((i) => i.toEntity()).toList(),
        onboardingComplete: onboardingComplete,
        createdAt: createdAt,
      );

  factory UserProfileModel.fromEntity(UserProfile profile) => UserProfileModel(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        avatarUrl: profile.avatarUrl,
        age: profile.age,
        height: profile.height,
        weight: profile.weight,
        activityLevel: profile.activityLevel?.name,
        trainingGoal: _trainingGoalToString(profile.trainingGoal),
        sportsTags: profile.sportsTags,
        trainingDaysPerWeek: profile.trainingDaysPerWeek,
        availableEquipment: profile.availableEquipment,
        injuries:
            profile.injuries.map((i) => InjuryModel.fromEntity(i)).toList(),
        onboardingComplete: profile.onboardingComplete,
        createdAt: profile.createdAt,
      );

  static ActivityLevel? _parseActivityLevel(String? value) {
    if (value == null) return null;
    const mapping = {
      'sedentary': ActivityLevel.sedentary,
      'lightlyActive': ActivityLevel.lightlyActive,
      'lightly_active': ActivityLevel.lightlyActive,
      'moderatelyActive': ActivityLevel.moderatelyActive,
      'moderately_active': ActivityLevel.moderatelyActive,
      'veryActive': ActivityLevel.veryActive,
      'very_active': ActivityLevel.veryActive,
      'extremelyActive': ActivityLevel.extremelyActive,
      'extremely_active': ActivityLevel.extremelyActive,
    };
    return mapping[value];
  }

  static TrainingGoal? _parseTrainingGoal(String? value) {
    if (value == null) return null;
    const mapping = {
      'generalFitness': TrainingGoal.generalFitness,
      'general_fitness': TrainingGoal.generalFitness,
      'strength': TrainingGoal.strength,
      'mobility': TrainingGoal.mobility,
      'longevity': TrainingGoal.longevity,
      'sportSpecific': TrainingGoal.sportSpecific,
      'sport_specific': TrainingGoal.sportSpecific,
      'rehab': TrainingGoal.rehab,
    };
    return mapping[value];
  }

  static String? _trainingGoalToString(TrainingGoal? goal) {
    if (goal == null) return null;
    const mapping = {
      TrainingGoal.generalFitness: 'general_fitness',
      TrainingGoal.strength: 'strength',
      TrainingGoal.mobility: 'mobility',
      TrainingGoal.longevity: 'longevity',
      TrainingGoal.sportSpecific: 'sport_specific',
      TrainingGoal.rehab: 'rehab',
    };
    return mapping[goal];
  }
}
