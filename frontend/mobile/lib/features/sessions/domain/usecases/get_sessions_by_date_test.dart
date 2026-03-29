import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';
import 'package:way2move/features/sessions/domain/usecases/get_sessions_by_date.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository mockRepo;
  late GetSessionsByDate getSessionsByDate;

  final tDate = DateTime(2026, 3, 29);
  final tSession = Session(
    id: 's1',
    userId: 'user1',
    date: tDate,
    status: SessionStatus.planned,
    exerciseBlocks: const [],
  );

  setUp(() {
    mockRepo = MockSessionRepository();
    getSessionsByDate = GetSessionsByDate(mockRepo);
  });

  group('GetSessionsByDate', () {
    test('returns a stream of sessions for the given date', () {
      when(() => mockRepo.watchSessionsByDate(any(), any()))
          .thenAnswer((_) => Stream.value([tSession]));

      final stream = getSessionsByDate('user1', tDate);

      expect(stream, emits([tSession]));
      verify(() => mockRepo.watchSessionsByDate('user1', tDate)).called(1);
    });

    test('returns empty list when no sessions exist for date', () {
      when(() => mockRepo.watchSessionsByDate(any(), any()))
          .thenAnswer((_) => Stream.value([]));

      final stream = getSessionsByDate('user1', tDate);

      expect(stream, emits(isEmpty));
    });
  });
}
