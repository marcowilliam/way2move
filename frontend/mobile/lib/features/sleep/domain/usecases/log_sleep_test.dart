import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/sleep/domain/entities/sleep_log.dart';
import 'package:way2move/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:way2move/features/sleep/domain/usecases/log_sleep.dart';

class MockSleepRepository extends Mock implements SleepRepository {}

SleepLog _testLog({String id = 's1'}) => SleepLog(
      id: id,
      userId: 'u1',
      bedTime: DateTime(2024, 1, 1, 22, 0),
      wakeTime: DateTime(2024, 1, 2, 6, 0),
      quality: 4,
      date: DateTime(2024, 1, 2),
    );

void main() {
  late MockSleepRepository mockRepo;
  late LogSleep logSleep;

  setUp(() {
    mockRepo = MockSleepRepository();
    logSleep = LogSleep(mockRepo);
  });

  setUpAll(() {
    registerFallbackValue(_testLog());
  });

  group('LogSleep', () {
    test('returns SleepLog on success', () async {
      final log = _testLog();
      when(() => mockRepo.logSleep(log)).thenAnswer((_) async => Right(log));

      final result = await logSleep(log);

      expect(result, Right(log));
      verify(() => mockRepo.logSleep(log)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      final log = _testLog();
      when(() => mockRepo.logSleep(log))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await logSleep(log);

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });

    test('forwards NetworkFailure from repository', () async {
      final log = _testLog();
      when(() => mockRepo.logSleep(log))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await logSleep(log);

      expect(result, const Left(NetworkFailure()));
    });
  });
}
