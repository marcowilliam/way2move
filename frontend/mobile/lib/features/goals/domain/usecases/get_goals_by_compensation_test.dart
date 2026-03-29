import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/domain/repositories/goal_repository.dart';
import 'package:way2move/features/goals/domain/usecases/get_goals_by_compensation.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

Goal _goal(String id, String compensationId) => Goal(
      id: id,
      userId: 'u1',
      name: 'Goal $id',
      category: GoalCategory.stability,
      targetMetric: 'reps',
      targetValue: 10,
      unit: 'reps',
      source: GoalSource.suggested,
      compensationIds: [compensationId],
    );

void main() {
  late MockGoalRepository mockRepo;
  late GetGoalsByCompensation getGoalsByCompensation;

  setUp(() {
    mockRepo = MockGoalRepository();
    getGoalsByCompensation = GetGoalsByCompensation(mockRepo);
  });

  group('GetGoalsByCompensation', () {
    test('returns goals linked to a specific compensation', () async {
      final goals = [_goal('g1', 'comp1')];
      when(() => mockRepo.getByCompensation('u1', 'comp1'))
          .thenAnswer((_) async => Right(goals));

      final result = await getGoalsByCompensation('u1', 'comp1');

      expect(result.isRight(), true);
      expect(result.getRight().toNullable(), goals);
      verify(() => mockRepo.getByCompensation('u1', 'comp1')).called(1);
    });

    test('returns empty list when no goals are linked to compensation',
        () async {
      when(() => mockRepo.getByCompensation('u1', 'comp1'))
          .thenAnswer((_) async => const Right([]));

      final result = await getGoalsByCompensation('u1', 'comp1');

      expect(result.isRight(), true);
      expect(result.getRight().toNullable(), isEmpty);
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.getByCompensation('u1', 'comp1'))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getGoalsByCompensation('u1', 'comp1');

      expect(result.isLeft(), true);
    });
  });
}
