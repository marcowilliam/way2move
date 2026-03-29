import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/profile/domain/entities/user_profile.dart';
import 'package:way2move/features/profile/domain/repositories/profile_repository.dart';
import 'package:way2move/features/profile/domain/usecases/get_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepo;
  late GetProfile getProfile;

  final tProfile = UserProfile(
    id: 'uid1',
    name: 'Test User',
    email: 'test@way2move.com',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = MockProfileRepository();
    getProfile = GetProfile(mockRepo);
  });

  group('GetProfile', () {
    test('returns UserProfile on success', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => Right(tProfile));

      final result = await getProfile('uid1');

      expect(result, Right(tProfile));
      verify(() => mockRepo.getProfile('uid1')).called(1);
    });

    test('returns NotFoundFailure when profile does not exist', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await getProfile('unknown');

      expect(result, const Left(NotFoundFailure()));
    });

    test('returns ServerFailure on unexpected error', () async {
      when(() => mockRepo.getProfile(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getProfile('uid1');

      expect(result, const Left(ServerFailure()));
    });
  });
}
