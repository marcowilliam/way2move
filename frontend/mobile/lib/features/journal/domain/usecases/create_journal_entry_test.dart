import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/journal/domain/entities/journal_entry.dart';
import 'package:way2move/features/journal/domain/repositories/journal_repository.dart';
import 'package:way2move/features/journal/domain/usecases/create_journal_entry.dart';

class MockJournalRepository extends Mock implements JournalRepository {}

JournalEntry _testEntry({String id = 'j1'}) => JournalEntry(
      id: id,
      userId: 'u1',
      date: DateTime(2024, 3, 1),
      type: JournalType.morningCheckIn,
      content: 'Felt good today, slept well.',
    );

void main() {
  late MockJournalRepository mockRepo;
  late CreateJournalEntry createJournalEntry;

  setUp(() {
    mockRepo = MockJournalRepository();
    createJournalEntry = CreateJournalEntry(mockRepo);
  });

  group('CreateJournalEntry', () {
    test('returns JournalEntry on success', () async {
      final entry = _testEntry();
      when(() => mockRepo.create(entry)).thenAnswer((_) async => Right(entry));

      final result = await createJournalEntry(entry);

      expect(result, Right(entry));
      verify(() => mockRepo.create(entry)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      final entry = _testEntry();
      when(() => mockRepo.create(entry))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await createJournalEntry(entry);

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });

    test('delegates directly to repository without modification', () async {
      final entry = _testEntry(id: 'j99');
      when(() => mockRepo.create(entry)).thenAnswer((_) async => Right(entry));

      await createJournalEntry(entry);

      verify(() => mockRepo.create(entry)).called(1);
      verifyNoMoreInteractions(mockRepo);
    });
  });
}
