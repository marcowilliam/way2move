import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/programs/domain/entities/program.dart';
import 'package:way2move/features/programs/domain/repositories/program_repository.dart';
import 'package:way2move/features/programs/domain/usecases/get_active_program.dart';

class MockProgramRepository extends Mock implements ProgramRepository {}

void main() {
  late MockProgramRepository mockRepo;
  late GetActiveProgram getActiveProgram;

  final tProgram = Program(
    id: 'p1',
    userId: 'user_1',
    name: 'Active Program',
    goal: 'Improve mobility',
    durationWeeks: 8,
    weekTemplate: WeekTemplate.empty(),
    isActive: true,
    createdAt: DateTime(2026, 3, 29),
  );

  setUp(() {
    mockRepo = MockProgramRepository();
    getActiveProgram = GetActiveProgram(mockRepo);
  });

  group('GetActiveProgram', () {
    test('returns Program when one is active', () async {
      when(() => mockRepo.getActiveProgram('user_1'))
          .thenAnswer((_) async => Right(tProgram));

      final result = await getActiveProgram('user_1');

      expect(result, Right(tProgram));
      verify(() => mockRepo.getActiveProgram('user_1')).called(1);
    });

    test('returns null when no active program', () async {
      when(() => mockRepo.getActiveProgram('user_1'))
          .thenAnswer((_) async => const Right(null));

      final result = await getActiveProgram('user_1');

      expect(result, const Right(null));
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.getActiveProgram('user_1'))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getActiveProgram('user_1');

      expect(result.isLeft(), true);
    });
  });
}
