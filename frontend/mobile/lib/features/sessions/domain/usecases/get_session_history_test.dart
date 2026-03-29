import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';
import 'package:way2move/features/sessions/domain/usecases/get_session_history.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository mockRepo;
  late GetSessionHistory getSessionHistory;

  final tSessions = [
    Session(
      id: 's1',
      userId: 'user1',
      date: DateTime(2026, 3, 28),
      status: SessionStatus.completed,
      exerciseBlocks: const [],
    ),
    Session(
      id: 's2',
      userId: 'user1',
      date: DateTime(2026, 3, 25),
      status: SessionStatus.completed,
      exerciseBlocks: const [],
    ),
  ];

  setUp(() {
    mockRepo = MockSessionRepository();
    getSessionHistory = GetSessionHistory(mockRepo);
  });

  group('GetSessionHistory', () {
    test('returns list of sessions on success', () async {
      when(() => mockRepo.getSessionHistory(any()))
          .thenAnswer((_) async => Right(tSessions));

      final result = await getSessionHistory('user1');

      expect(result, Right(tSessions));
      verify(() => mockRepo.getSessionHistory('user1')).called(1);
    });

    test('returns empty list when user has no sessions', () async {
      when(() => mockRepo.getSessionHistory(any()))
          .thenAnswer((_) async => const Right([]));

      final result = await getSessionHistory('user1');

      expect(result, const Right(<Session>[]));
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.getSessionHistory(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getSessionHistory('user1');

      expect(result.isLeft(), true);
    });
  });
}
