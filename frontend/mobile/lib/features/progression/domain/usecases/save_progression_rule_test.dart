import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/progression/domain/entities/progression_rule.dart';
import 'package:way2move/features/progression/domain/repositories/progression_rule_repository.dart';
import 'package:way2move/features/progression/domain/usecases/save_progression_rule.dart';

class MockProgressionRuleRepository extends Mock
    implements ProgressionRuleRepository {}

void main() {
  late MockProgressionRuleRepository mockRepo;
  late SaveProgressionRule saveProgressionRule;

  setUp(() {
    mockRepo = MockProgressionRuleRepository();
    saveProgressionRule = SaveProgressionRule(mockRepo);
  });

  setUpAll(() {
    registerFallbackValue(const ProgressionRule());
  });

  test('calls saveGlobalRule when rule has no exerciseId', () async {
    const globalRule = ProgressionRule(); // exerciseId is '' = global
    when(() => mockRepo.saveGlobalRule(any()))
        .thenAnswer((_) async => const Right(globalRule));

    final result = await saveProgressionRule(globalRule);

    expect(result.isRight(), true);
    verify(() => mockRepo.saveGlobalRule(globalRule)).called(1);
    verifyNever(() => mockRepo.saveRule(any()));
  });

  test('calls saveRule when rule has a specific exerciseId', () async {
    const exerciseRule = ProgressionRule(exerciseId: 'ex1');
    when(() => mockRepo.saveRule(any()))
        .thenAnswer((_) async => const Right(exerciseRule));

    final result = await saveProgressionRule(exerciseRule);

    expect(result.isRight(), true);
    verify(() => mockRepo.saveRule(exerciseRule)).called(1);
    verifyNever(() => mockRepo.saveGlobalRule(any()));
  });

  test('returns Left when repository fails', () async {
    const exerciseRule = ProgressionRule(exerciseId: 'ex_bad');
    when(() => mockRepo.saveRule(any()))
        .thenAnswer((_) async => const Left(ServerFailure('write-error')));

    final result = await saveProgressionRule(exerciseRule);

    expect(result.isLeft(), true);
  });
}
