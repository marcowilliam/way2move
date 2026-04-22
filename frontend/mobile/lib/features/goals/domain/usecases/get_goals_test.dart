import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/domain/repositories/goal_repository.dart';
import 'package:way2move/features/goals/domain/usecases/get_goals.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

Goal _goal(String id) => Goal(
      id: id,
      userId: 'u1',
      name: 'Goal $id',
      category: GoalCategory.stability,
      targetMetric: 'reps',
      targetValue: 10,
      unit: 'reps',
      origin: GoalOrigin.manual,
    );

void main() {
  late MockGoalRepository mockRepo;
  late GetGoals getGoals;

  setUp(() {
    mockRepo = MockGoalRepository();
    getGoals = GetGoals(mockRepo);
  });

  group('GetGoals', () {
    test('returns list of goals for user', () async {
      final goals = [_goal('g1'), _goal('g2')];
      when(() => mockRepo.getAll('u1')).thenAnswer((_) async => Right(goals));

      final result = await getGoals('u1');

      expect(result.isRight(), true);
      expect(result.getRight().toNullable(), goals);
    });

    test('returns empty list when user has no goals', () async {
      when(() => mockRepo.getAll('u1'))
          .thenAnswer((_) async => const Right([]));

      final result = await getGoals('u1');

      expect(result.isRight(), true);
      expect(result.getRight().toNullable(), isEmpty);
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.getAll('u1'))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getGoals('u1');

      expect(result.isLeft(), true);
    });
  });
}
