import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';
import 'mark_compensation_improving.dart';

class MockCompensationRepository extends Mock
    implements CompensationRepository {}

void main() {
  late MockCompensationRepository mockRepo;
  late MarkCompensationImproving useCase;

  final tImproving = Compensation(
    id: 'comp1',
    userId: 'user1',
    name: 'Anterior Pelvic Tilt',
    type: CompensationType.posturalPattern,
    region: CompensationRegion.pelvis,
    severity: CompensationSeverity.mild,
    status: CompensationStatus.improving,
    origin: CompensationOrigin.assessment,
    detectedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockRepo = MockCompensationRepository();
    useCase = MarkCompensationImproving(mockRepo);
  });

  test('returns compensation with improving status on success', () async {
    when(() => mockRepo.markImproving(any(), any()))
        .thenAnswer((_) async => Right(tImproving));

    final result = await useCase('comp1', 'Feeling better after stretching');

    expect(result, Right(tImproving));
    expect(
        result.getRight().toNullable()!.status, CompensationStatus.improving);
    verify(() =>
            mockRepo.markImproving('comp1', 'Feeling better after stretching'))
        .called(1);
  });

  test('returns NotFoundFailure when compensation does not exist', () async {
    when(() => mockRepo.markImproving(any(), any()))
        .thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase('nonexistent', 'note');

    expect(result, const Left(NotFoundFailure()));
  });
}
