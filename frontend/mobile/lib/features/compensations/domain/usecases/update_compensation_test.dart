import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';
import 'update_compensation.dart';

class MockCompensationRepository extends Mock
    implements CompensationRepository {}

void main() {
  late MockCompensationRepository mockRepo;
  late UpdateCompensation useCase;

  final tCompensation = Compensation(
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
    useCase = UpdateCompensation(mockRepo);
    registerFallbackValue(tCompensation);
  });

  test('returns updated Compensation on success', () async {
    when(() => mockRepo.update(any()))
        .thenAnswer((_) async => Right(tCompensation));

    final result = await useCase(tCompensation);

    expect(result, Right(tCompensation));
    verify(() => mockRepo.update(tCompensation)).called(1);
  });

  test('returns NotFoundFailure when compensation does not exist', () async {
    when(() => mockRepo.update(any()))
        .thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase(tCompensation);

    expect(result, const Left(NotFoundFailure()));
  });
}
