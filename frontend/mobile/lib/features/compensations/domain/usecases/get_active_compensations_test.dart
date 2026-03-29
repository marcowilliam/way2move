import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';
import 'get_active_compensations.dart';

class MockCompensationRepository extends Mock
    implements CompensationRepository {}

void main() {
  late MockCompensationRepository mockRepo;
  late GetActiveCompensations useCase;

  final tActive = [
    Compensation(
      id: 'comp1',
      userId: 'user1',
      name: 'Anterior Pelvic Tilt',
      type: CompensationType.posturalPattern,
      region: CompensationRegion.pelvis,
      severity: CompensationSeverity.moderate,
      status: CompensationStatus.active,
      source: CompensationSource.assessment,
      detectedAt: DateTime(2026, 1, 1),
    ),
    Compensation(
      id: 'comp2',
      userId: 'user1',
      name: 'Rounded Shoulders',
      type: CompensationType.posturalPattern,
      region: CompensationRegion.leftShoulder,
      severity: CompensationSeverity.mild,
      status: CompensationStatus.active,
      source: CompensationSource.manual,
      detectedAt: DateTime(2026, 1, 2),
    ),
  ];

  setUp(() {
    mockRepo = MockCompensationRepository();
    useCase = GetActiveCompensations(mockRepo);
  });

  test('returns list of active compensations for user', () async {
    when(() => mockRepo.getActive(any()))
        .thenAnswer((_) async => Right(tActive));

    final result = await useCase('user1');

    expect(result, Right(tActive));
    verify(() => mockRepo.getActive('user1')).called(1);
  });

  test('returns empty list when user has no active compensations', () async {
    when(() => mockRepo.getActive(any()))
        .thenAnswer((_) async => const Right([]));

    final result = await useCase('user1');

    expect(result, const Right(<Compensation>[]));
  });

  test('returns ServerFailure on repository error', () async {
    when(() => mockRepo.getActive(any()))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase('user1');

    expect(result.isLeft(), true);
  });
}
