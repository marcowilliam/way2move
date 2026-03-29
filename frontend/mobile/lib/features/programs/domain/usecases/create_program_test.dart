import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/programs/domain/entities/program.dart';
import 'package:way2move/features/programs/domain/repositories/program_repository.dart';
import 'package:way2move/features/programs/domain/usecases/create_program.dart';

class MockProgramRepository extends Mock implements ProgramRepository {}

void main() {
  late MockProgramRepository mockRepo;
  late CreateProgram createProgram;

  final tProgram = Program(
    id: 'p1',
    userId: 'user_1',
    name: 'Corrective Movement Program',
    goal: 'Fix anterior pelvic tilt',
    durationWeeks: 8,
    weekTemplate: WeekTemplate.empty(),
    isActive: true,
    createdAt: DateTime(2026, 3, 29),
  );

  setUp(() {
    mockRepo = MockProgramRepository();
    createProgram = CreateProgram(mockRepo);
    registerFallbackValue(tProgram);
  });

  group('CreateProgram', () {
    test('returns Program on success', () async {
      when(() => mockRepo.createProgram(any()))
          .thenAnswer((_) async => Right(tProgram));

      final result = await createProgram(tProgram);

      expect(result, Right(tProgram));
      verify(() => mockRepo.createProgram(tProgram)).called(1);
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.createProgram(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await createProgram(tProgram);

      expect(result.isLeft(), true);
    });
  });
}
