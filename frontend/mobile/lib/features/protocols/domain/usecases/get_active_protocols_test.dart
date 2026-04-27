import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/protocols/domain/entities/protocol.dart';
import 'package:way2move/features/protocols/domain/repositories/protocol_repository.dart';
import 'package:way2move/features/protocols/domain/usecases/get_active_protocols.dart';
import 'package:way2move/features/workouts/domain/entities/workout_enums.dart';

class MockProtocolRepository extends Mock implements ProtocolRepository {}

void main() {
  late MockProtocolRepository mockRepo;
  late GetActiveProtocols getActive;

  final tProtocol = Protocol(
    id: 'p1',
    userId: 'user1',
    name: 'From the Ground Up',
    kind: ProtocolKind.physio,
    startDate: DateTime(2026, 4, 27),
    endDate: DateTime(2026, 6, 8),
    durationWeeks: 6,
    prescription: 'all exercises every day, 1 set each',
    workoutIds: const ['ground-up'],
  );

  setUp(() {
    mockRepo = MockProtocolRepository();
    getActive = GetActiveProtocols(mockRepo);
  });

  test('returns list of active protocols from repository', () async {
    when(() => mockRepo.getActiveProtocols('user1'))
        .thenAnswer((_) async => Right([tProtocol]));

    final result = await getActive('user1');

    expect(result.getRight().toNullable(), equals([tProtocol]));
  });

  test('propagates failure from repository', () async {
    when(() => mockRepo.getActiveProtocols(any()))
        .thenAnswer((_) async => const Left(ServerFailure('offline')));

    final result = await getActive('user1');

    expect(result.isLeft(), true);
  });
}
