class Injury {
  final String bodyRegion;
  final String description;
  final InjurySeverity severity;
  final bool isActive;

  const Injury({
    required this.bodyRegion,
    required this.description,
    required this.severity,
    this.isActive = true,
  });

  Injury copyWith({
    String? bodyRegion,
    String? description,
    InjurySeverity? severity,
    bool? isActive,
  }) {
    return Injury(
      bodyRegion: bodyRegion ?? this.bodyRegion,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Injury &&
      other.bodyRegion == bodyRegion &&
      other.description == description &&
      other.severity == severity &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(bodyRegion, description, severity, isActive);
}

enum InjurySeverity { minor, moderate, severe }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive,
}

enum TrainingGoal {
  generalFitness,
  strength,
  mobility,
  longevity,
  sportSpecific,
  rehab,
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int? age;
  final double? height;
  final double? weight;
  final ActivityLevel? activityLevel;
  final TrainingGoal? trainingGoal;
  final List<String> sportsTags;
  final int? trainingDaysPerWeek;
  final List<String> availableEquipment;
  final List<Injury> injuries;
  final bool onboardingComplete;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
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

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? age,
    double? height,
    double? weight,
    ActivityLevel? activityLevel,
    TrainingGoal? trainingGoal,
    List<String>? sportsTags,
    int? trainingDaysPerWeek,
    List<String>? availableEquipment,
    List<Injury>? injuries,
    bool? onboardingComplete,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      sportsTags: sportsTags ?? this.sportsTags,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      injuries: injuries ?? this.injuries,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
