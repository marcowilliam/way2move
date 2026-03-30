import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/journal/domain/entities/journal_entry.dart';
import 'package:way2move/features/journal/domain/repositories/journal_repository.dart';
import 'package:way2move/features/journal/domain/usecases/get_journals_for_session.dart';

class MockJournalRepository extends Mock implements JournalRepository {}

JournalEntry _entry(String id) => JournalEntry(
      id: id,
      userId: 'u1',
      date: DateTime(2024, 3, 1),
      type: JournalType.postSession,
      content: 'Great session today.',
      linkedSessionId: 'sess1',
    );

void main() {
  late MockJournalRepository mockRepo;
  late GetJournalsForSession getJournalsForSession;

  setUp(() {
    mockRepo = MockJournalRepository();
    getJournalsForSession = GetJournalsForSession(mockRepo);
  });

  group('GetJournalsForSession', () {
    test('returns entries linked to the given session', () async {
      final entries = [_entry('j1'), _entry('j2')];
      when(() => mockRepo.getForSession('u1', 'sess1'))
          .thenAnswer((_) async => Right(entries));

      final result = await getJournalsForSession('u1', 'sess1');

      expect(result, Right(entries));
      verify(() => mockRepo.getForSession('u1', 'sess1')).called(1);
    });

    test('returns empty list when no journals linked to session', () async {
      when(() => mockRepo.getForSession('u1', 'sess_none'))
          .thenAnswer((_) async => const Right([]));

      final result = await getJournalsForSession('u1', 'sess_none');

      expect(result, const Right(<JournalEntry>[]));
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.getForSession(any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getJournalsForSession('u1', 'sess1');

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
