import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';
import 'create_compensation.dart';

class MockCompensationRepository extends Mock
    implements CompensationRepository {}

void main() {
  late MockCompensationRepository mockRepo;
  late CreateCompensation useCase;

  final tCompensation = Compensation(
    id: 'comp1',
    userId: 'user1',
    name: 'Anterior Pelvic Tilt',
    type: CompensationType.posturalPattern,
    region: CompensationRegion.pelvis,
    severity: CompensationSeverity.moderate,
    status: CompensationStatus.active,
    origin: CompensationOrigin.assessment,
    detectedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockRepo = MockCompensationRepository();
    useCase = CreateCompensation(mockRepo);
    registerFallbackValue(tCompensation);
  });

  test('returns created Compensation on success', () async {
    when(() => mockRepo.create(any()))
        .thenAnswer((_) async => Right(tCompensation));

    final result = await useCase(tCompensation);

    expect(result, Right(tCompensation));
    verify(() => mockRepo.create(tCompensation)).called(1);
  });

  test('returns ServerFailure when repository fails', () async {
    when(() => mockRepo.create(any()))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(tCompensation);

    expect(result.isLeft(), true);
  });
}
