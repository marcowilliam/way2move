import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';
import 'mark_compensation_resolved.dart';

class MockCompensationRepository extends Mock
    implements CompensationRepository {}

void main() {
  late MockCompensationRepository mockRepo;
  late MarkCompensationResolved useCase;

  final tResolved = Compensation(
    id: 'comp1',
    userId: 'user1',
    name: 'Anterior Pelvic Tilt',
    type: CompensationType.posturalPattern,
    region: CompensationRegion.pelvis,
    severity: CompensationSeverity.mild,
    status: CompensationStatus.resolved,
    source: CompensationSource.assessment,
    detectedAt: DateTime(2026, 1, 1),
    resolvedAt: DateTime(2026, 3, 1),
  );

  setUp(() {
    mockRepo = MockCompensationRepository();
    useCase = MarkCompensationResolved(mockRepo);
  });

  test('returns compensation with resolved status on success', () async {
    when(() => mockRepo.markResolved(any(), any()))
        .thenAnswer((_) async => Right(tResolved));

    final result = await useCase('comp1', 'No longer experiencing issues');

    expect(result, Right(tResolved));
    expect(result.getRight().toNullable()!.status, CompensationStatus.resolved);
    verify(() =>
            mockRepo.markResolved('comp1', 'No longer experiencing issues'))
        .called(1);
  });

  test('returns NotFoundFailure when compensation does not exist', () async {
    when(() => mockRepo.markResolved(any(), any()))
        .thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase('nonexistent', 'note');

    expect(result, const Left(NotFoundFailure()));
  });

  test('resolved compensation has resolvedAt timestamp', () async {
    when(() => mockRepo.markResolved(any(), any()))
        .thenAnswer((_) async => Right(tResolved));

    final result = await useCase('comp1', 'All clear');

    expect(result.getRight().toNullable()!.resolvedAt, isNotNull);
  });
}
