import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/profile/domain/entities/user_profile.dart';
import 'package:way2move/features/profile/domain/repositories/profile_repository.dart';
import 'package:way2move/features/profile/domain/usecases/update_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepo;
  late UpdateProfile updateProfile;

  final tProfile = UserProfile(
    id: 'uid1',
    name: 'Test User',
    email: 'test@way2move.com',
    age: 30,
    trainingGoal: TrainingGoal.generalFitness,
    activityLevel: ActivityLevel.moderatelyActive,
    sportsTags: ['running'],
    trainingDaysPerWeek: 3,
    availableEquipment: ['bodyweight', 'dumbbells'],
    onboardingComplete: true,
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = MockProfileRepository();
    updateProfile = UpdateProfile(mockRepo);
  });

  setUpAll(() {
    registerFallbackValue(tProfile);
  });

  group('UpdateProfile', () {
    test('returns updated UserProfile on success', () async {
      when(() => mockRepo.updateProfile(any()))
          .thenAnswer((_) async => Right(tProfile));

      final result = await updateProfile(tProfile);

      expect(result, Right(tProfile));
      verify(() => mockRepo.updateProfile(tProfile)).called(1);
    });

    test('returns ServerFailure on unexpected error', () async {
      when(() => mockRepo.updateProfile(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await updateProfile(tProfile);

      expect(result, const Left(ServerFailure()));
    });

    test('returns ValidationFailure when name is empty', () async {
      final invalidProfile = tProfile.copyWith(name: '');
      when(() => mockRepo.updateProfile(any())).thenAnswer(
          (_) async => const Left(ValidationFailure('Name cannot be empty')));

      final result = await updateProfile(invalidProfile);

      expect(result.isLeft(), true);
    });

    test('preserves all profile fields through update', () async {
      when(() => mockRepo.updateProfile(any()))
          .thenAnswer((_) async => Right(tProfile));

      final result = await updateProfile(tProfile);

      result.fold(
        (_) => fail('Expected Right'),
        (profile) {
          expect(profile.age, 30);
          expect(profile.trainingGoal, TrainingGoal.generalFitness);
          expect(profile.sportsTags, ['running']);
          expect(profile.availableEquipment, ['bodyweight', 'dumbbells']);
          expect(profile.onboardingComplete, true);
        },
      );
    });
  });
}
