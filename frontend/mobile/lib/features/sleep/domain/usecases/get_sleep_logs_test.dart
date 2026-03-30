import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/sleep/domain/entities/sleep_log.dart';
import 'package:way2move/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:way2move/features/sleep/domain/usecases/get_sleep_logs.dart';

class MockSleepRepository extends Mock implements SleepRepository {}

SleepLog _testLog(String id) => SleepLog(
      id: id,
      userId: 'u1',
      bedTime: DateTime(2024, 1, 1, 22, 0),
      wakeTime: DateTime(2024, 1, 2, 6, 0),
      quality: 3,
      date: DateTime(2024, 1, 2),
    );

void main() {
  late MockSleepRepository mockRepo;
  late GetSleepLogs getSleepLogs;

  setUp(() {
    mockRepo = MockSleepRepository();
    getSleepLogs = GetSleepLogs(mockRepo);
  });

  group('GetSleepLogs', () {
    test('returns list of sleep logs on success', () async {
      final logs = [_testLog('s1'), _testLog('s2')];
      when(() => mockRepo.getSleepLogs('u1', limit: 30))
          .thenAnswer((_) async => Right(logs));

      final result = await getSleepLogs('u1');

      expect(result, Right(logs));
      verify(() => mockRepo.getSleepLogs('u1', limit: 30)).called(1);
    });

    test('returns empty list when no logs exist', () async {
      when(() => mockRepo.getSleepLogs('u1', limit: 30))
          .thenAnswer((_) async => const Right([]));

      final result = await getSleepLogs('u1');

      expect(result, const Right(<SleepLog>[]));
    });

    test('passes custom limit to repository', () async {
      when(() => mockRepo.getSleepLogs('u1', limit: 7))
          .thenAnswer((_) async => const Right([]));

      await getSleepLogs('u1', limit: 7);

      verify(() => mockRepo.getSleepLogs('u1', limit: 7)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.getSleepLogs('u1', limit: 30))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getSleepLogs('u1');

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
