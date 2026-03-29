import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';
import 'package:way2move/features/sessions/domain/usecases/update_session.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository mockRepo;
  late UpdateSession updateSession;

  final tSession = Session(
    id: 's1',
    userId: 'user1',
    date: DateTime(2026, 3, 29),
    status: SessionStatus.completed,
    exerciseBlocks: const [],
    durationMinutes: 45,
  );

  setUp(() {
    mockRepo = MockSessionRepository();
    updateSession = UpdateSession(mockRepo);
    registerFallbackValue(tSession);
  });

  group('UpdateSession', () {
    test('returns updated Session on success', () async {
      when(() => mockRepo.updateSession(any()))
          .thenAnswer((_) async => Right(tSession));

      final result = await updateSession(tSession);

      expect(result, Right(tSession));
      verify(() => mockRepo.updateSession(tSession)).called(1);
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.updateSession(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await updateSession(tSession);

      expect(result.isLeft(), true);
    });
  });
}
