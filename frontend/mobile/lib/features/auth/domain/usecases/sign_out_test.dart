import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/auth/domain/repositories/auth_repository.dart';
import 'package:way2move/features/auth/domain/usecases/sign_out.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late SignOut signOut;

  setUp(() {
    mockRepo = MockAuthRepository();
    signOut = SignOut(mockRepo);
  });

  group('SignOut', () {
    test('delegates sign out to repository', () async {
      when(() => mockRepo.signOut()).thenAnswer((_) async => const Right(unit));

      final result = await signOut();

      expect(result, const Right(unit));
      verify(() => mockRepo.signOut()).called(1);
    });
  });
}
