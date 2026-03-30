import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/journal/domain/entities/journal_entry.dart';
import 'package:way2move/features/journal/domain/repositories/journal_repository.dart';
import 'package:way2move/features/journal/domain/usecases/get_journals_by_date.dart';

class MockJournalRepository extends Mock implements JournalRepository {}

JournalEntry _entry(String id, JournalType type) => JournalEntry(
      id: id,
      userId: 'u1',
      date: DateTime(2024, 3, 1),
      type: type,
      content: 'Test content',
    );

void main() {
  late MockJournalRepository mockRepo;
  late GetJournalsByDate getJournalsByDate;
  final testDate = DateTime(2024, 3, 1);

  setUp(() {
    mockRepo = MockJournalRepository();
    getJournalsByDate = GetJournalsByDate(mockRepo);
  });

  group('GetJournalsByDate', () {
    test('returns list of entries for given date', () async {
      final entries = [
        _entry('j1', JournalType.morningCheckIn),
        _entry('j2', JournalType.eveningReflection),
      ];
      when(() => mockRepo.getByDate('u1', testDate))
          .thenAnswer((_) async => Right(entries));

      final result = await getJournalsByDate('u1', testDate);

      expect(result, Right(entries));
      verify(() => mockRepo.getByDate('u1', testDate)).called(1);
    });

    test('returns empty list when no entries for that date', () async {
      when(() => mockRepo.getByDate('u1', testDate))
          .thenAnswer((_) async => const Right([]));

      final result = await getJournalsByDate('u1', testDate);

      expect(result, const Right(<JournalEntry>[]));
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.getByDate(any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getJournalsByDate('u1', testDate);

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
