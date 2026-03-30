import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/progression/domain/entities/progression_rule.dart';
import 'package:way2move/features/progression/domain/repositories/progression_rule_repository.dart';
import 'package:way2move/features/progression/domain/usecases/get_progression_rule.dart';

class MockProgressionRuleRepository extends Mock
    implements ProgressionRuleRepository {}

void main() {
  late MockProgressionRuleRepository mockRepo;
  late GetProgressionRule getProgressionRule;

  setUp(() {
    mockRepo = MockProgressionRuleRepository();
    getProgressionRule = GetProgressionRule(mockRepo);
  });

  test('calls getGlobalRule when exerciseId is empty', () async {
    const globalRule = ProgressionRule();
    when(() => mockRepo.getGlobalRule())
        .thenAnswer((_) async => const Right(globalRule));

    final result = await getProgressionRule('');

    expect(result.isRight(), true);
    verify(() => mockRepo.getGlobalRule()).called(1);
    verifyNever(() => mockRepo.getRule(any()));
  });

  test('calls getRule when exerciseId is non-empty', () async {
    const exerciseRule = ProgressionRule(exerciseId: 'ex1');
    when(() => mockRepo.getRule('ex1'))
        .thenAnswer((_) async => const Right(exerciseRule));

    final result = await getProgressionRule('ex1');

    expect(result.isRight(), true);
    verify(() => mockRepo.getRule('ex1')).called(1);
    verifyNever(() => mockRepo.getGlobalRule());
  });

  test('returns Left on repository error', () async {
    when(() => mockRepo.getRule(any()))
        .thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await getProgressionRule('nonexistent');

    expect(result.isLeft(), true);
  });
}
