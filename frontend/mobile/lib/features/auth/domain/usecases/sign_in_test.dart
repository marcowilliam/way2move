import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/auth/domain/entities/user.dart';
import 'package:way2move/features/auth/domain/repositories/auth_repository.dart';
import 'package:way2move/features/auth/domain/usecases/sign_in.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late SignIn signIn;

  final tUser = AppUser(
    id: 'uid1',
    email: 'test@way2move.com',
    name: 'Test User',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    signIn = SignIn(mockRepo);
  });

  group('SignIn', () {
    test('returns AppUser on success', () async {
      when(() => mockRepo.signIn(any(), any()))
          .thenAnswer((_) async => Right(tUser));

      final result = await signIn('test@way2move.com', 'password');

      expect(result, Right(tUser));
      verify(() => mockRepo.signIn('test@way2move.com', 'password')).called(1);
    });

    test('returns AuthFailure when wrong password', () async {
      when(() => mockRepo.signIn(any(), any()))
          .thenAnswer((_) async => const Left(AuthFailure('wrong-password')));

      final result = await signIn('test@way2move.com', 'wrong');

      expect(result, const Left(AuthFailure('wrong-password')));
    });

    test('returns AuthFailure when user not found', () async {
      when(() => mockRepo.signIn(any(), any()))
          .thenAnswer((_) async => const Left(AuthFailure('user-not-found')));

      final result = await signIn('unknown@way2move.com', 'password');

      expect(result.isLeft(), true);
    });

    test('returns NetworkFailure on network error', () async {
      when(() => mockRepo.signIn(any(), any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await signIn('test@way2move.com', 'password');

      expect(result, const Left(NetworkFailure()));
    });
  });
}
