import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';
import 'package:way2move/features/sessions/domain/usecases/create_session.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository mockRepo;
  late CreateSession createSession;

  final tSession = Session(
    id: 's1',
    userId: 'user1',
    date: DateTime(2026, 3, 29),
    status: SessionStatus.planned,
    exerciseBlocks: const [],
  );

  setUp(() {
    mockRepo = MockSessionRepository();
    createSession = CreateSession(mockRepo);
    registerFallbackValue(tSession);
  });

  group('CreateSession', () {
    test('returns Session on success', () async {
      when(() => mockRepo.createSession(any()))
          .thenAnswer((_) async => Right(tSession));

      final result = await createSession(tSession);

      expect(result, Right(tSession));
      verify(() => mockRepo.createSession(tSession)).called(1);
    });

    test('returns ServerFailure on repository error', () async {
      when(() => mockRepo.createSession(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await createSession(tSession);

      expect(result.isLeft(), true);
    });
  });
}
