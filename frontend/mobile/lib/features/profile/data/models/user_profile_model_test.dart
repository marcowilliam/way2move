import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/profile/data/models/user_profile_model.dart';
import 'package:way2move/features/profile/domain/entities/user_profile.dart';

void main() {
  group('UserProfileModel', () {
    final tProfile = UserProfile(
      id: 'uid1',
      name: 'Test User',
      email: 'test@way2move.com',
      age: 30,
      height: 175.0,
      weight: 70.0,
      activityLevel: ActivityLevel.moderatelyActive,
      trainingGoal: TrainingGoal.generalFitness,
      sportsTags: ['running', 'climbing'],
      trainingDaysPerWeek: 3,
      availableEquipment: ['bodyweight', 'dumbbells'],
      injuries: [
        const Injury(
          bodyRegion: 'left_shoulder',
          description: 'Rotator cuff strain',
          severity: InjurySeverity.moderate,
        ),
      ],
      onboardingComplete: true,
      createdAt: DateTime(2024),
    );

    test('fromEntity creates model from domain entity', () {
      final model = UserProfileModel.fromEntity(tProfile);

      expect(model.id, 'uid1');
      expect(model.name, 'Test User');
      expect(model.age, 30);
      expect(model.activityLevel, 'moderatelyActive');
      expect(model.trainingGoal, 'general_fitness');
      expect(model.sportsTags, ['running', 'climbing']);
      expect(model.injuries.length, 1);
      expect(model.injuries.first.bodyRegion, 'left_shoulder');
    });

    test('toEntity converts model back to domain entity', () {
      final model = UserProfileModel.fromEntity(tProfile);
      final entity = model.toEntity();

      expect(entity.id, 'uid1');
      expect(entity.name, 'Test User');
      expect(entity.age, 30);
      expect(entity.activityLevel, ActivityLevel.moderatelyActive);
      expect(entity.trainingGoal, TrainingGoal.generalFitness);
      expect(entity.sportsTags, ['running', 'climbing']);
      expect(entity.injuries.length, 1);
      expect(entity.injuries.first.severity, InjurySeverity.moderate);
    });

    test('toFirestore produces correct map', () {
      final model = UserProfileModel.fromEntity(tProfile);
      final map = model.toFirestore();

      expect(map['name'], 'Test User');
      expect(map['age'], 30);
      expect(map['height'], 175.0);
      expect(map['weight'], 70.0);
      expect(map['activityLevel'], 'moderatelyActive');
      expect(map['trainingGoal'], 'general_fitness');
      expect(map['sportsTags'], ['running', 'climbing']);
      expect(map['trainingDaysPerWeek'], 3);
      expect(map['availableEquipment'], ['bodyweight', 'dumbbells']);
      expect(map['onboardingComplete'], true);
      expect(map['injuries'], isList);
      expect((map['injuries'] as List).first['bodyRegion'], 'left_shoulder');
      // Does not include id or email (immutable fields)
      expect(map.containsKey('id'), false);
      expect(map.containsKey('email'), false);
    });

    test('handles null optional fields gracefully', () {
      final minimalProfile = UserProfile(
        id: 'uid2',
        name: 'Minimal',
        email: 'min@test.com',
        createdAt: DateTime(2024),
      );
      final model = UserProfileModel.fromEntity(minimalProfile);
      final entity = model.toEntity();

      expect(entity.age, isNull);
      expect(entity.height, isNull);
      expect(entity.weight, isNull);
      expect(entity.activityLevel, isNull);
      expect(entity.trainingGoal, isNull);
      expect(entity.sportsTags, isEmpty);
      expect(entity.injuries, isEmpty);
      expect(entity.onboardingComplete, false);
    });

    test('parses snake_case activity level from Firestore', () {
      // Simulate Firestore storing snake_case
      final model = UserProfileModel(
        id: 'uid1',
        name: 'Test',
        email: 'test@test.com',
        avatarUrl: '',
        activityLevel: 'very_active',
        createdAt: DateTime(2024),
      );
      final entity = model.toEntity();

      expect(entity.activityLevel, ActivityLevel.veryActive);
    });

    test('parses camelCase activity level from Firestore', () {
      final model = UserProfileModel(
        id: 'uid1',
        name: 'Test',
        email: 'test@test.com',
        avatarUrl: '',
        activityLevel: 'lightlyActive',
        createdAt: DateTime(2024),
      );
      final entity = model.toEntity();

      expect(entity.activityLevel, ActivityLevel.lightlyActive);
    });
  });

  group('InjuryModel', () {
    test('fromMap handles all fields', () {
      final map = {
        'bodyRegion': 'lower_back',
        'description': 'Disc herniation',
        'severity': 'severe',
        'isActive': true,
      };

      final model = InjuryModel.fromMap(map);

      expect(model.bodyRegion, 'lower_back');
      expect(model.description, 'Disc herniation');
      expect(model.severity, 'severe');
      expect(model.isActive, true);
    });

    test('toEntity maps severity string to enum', () {
      final model = InjuryModel.fromMap({
        'bodyRegion': 'knee',
        'description': 'Minor pain',
        'severity': 'minor',
        'isActive': true,
      });

      final entity = model.toEntity();

      expect(entity.severity, InjurySeverity.minor);
    });

    test('defaults to minor severity for unknown value', () {
      final model = InjuryModel.fromMap({
        'bodyRegion': 'knee',
        'description': 'Pain',
        'severity': 'unknown_severity',
        'isActive': true,
      });

      final entity = model.toEntity();

      expect(entity.severity, InjurySeverity.minor);
    });
  });
}
