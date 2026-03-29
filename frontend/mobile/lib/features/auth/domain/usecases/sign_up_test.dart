import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/auth/domain/entities/user.dart';
import 'package:way2move/features/auth/domain/repositories/auth_repository.dart';
import 'package:way2move/features/auth/domain/usecases/sign_up.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late SignUp signUp;

  final tUser = AppUser(
    id: 'uid1',
    email: 'new@way2move.com',
    name: 'New User',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    signUp = SignUp(mockRepo);
  });

  group('SignUp', () {
    test('returns AppUser on success', () async {
      when(() => mockRepo.signUp(any(), any(), any()))
          .thenAnswer((_) async => Right(tUser));

      final result = await signUp('new@way2move.com', 'Pass1234!', 'New User');

      expect(result, Right(tUser));
    });

    test('returns AuthFailure when email already in use', () async {
      when(() => mockRepo.signUp(any(), any(), any())).thenAnswer(
          (_) async => const Left(AuthFailure('email-already-in-use')));

      final result = await signUp('existing@way2move.com', 'Pass1234!', 'User');

      expect(result, const Left(AuthFailure('email-already-in-use')));
    });

    test('delegates to repository with correct arguments', () async {
      when(() => mockRepo.signUp(any(), any(), any()))
          .thenAnswer((_) async => Right(tUser));

      await signUp('new@way2move.com', 'Pass1234!', 'New User');

      verify(() => mockRepo.signUp('new@way2move.com', 'Pass1234!', 'New User'))
          .called(1);
    });
  });
}
