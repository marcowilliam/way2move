import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/domain/repositories/goal_repository.dart';
import 'package:way2move/features/goals/domain/usecases/update_goal.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

Goal _testGoal({double currentValue = 10}) => Goal(
      id: 'g1',
      userId: 'u1',
      name: 'Hip stability',
      category: GoalCategory.stability,
      targetMetric: 'clamshell reps',
      targetValue: 20,
      currentValue: currentValue,
      unit: 'reps',
      source: GoalSource.suggested,
    );

void main() {
  late MockGoalRepository mockRepo;
  late UpdateGoal updateGoal;

  setUp(() {
    mockRepo = MockGoalRepository();
    updateGoal = UpdateGoal(mockRepo);
  });

  group('UpdateGoal', () {
    test('returns updated Goal on success', () async {
      final goal = _testGoal(currentValue: 15);
      when(() => mockRepo.update(goal)).thenAnswer((_) async => Right(goal));

      final result = await updateGoal(goal);

      expect(result, Right(goal));
      verify(() => mockRepo.update(goal)).called(1);
    });

    test('returns NotFoundFailure when goal does not exist', () async {
      final goal = _testGoal();
      when(() => mockRepo.update(goal))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await updateGoal(goal);

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
    });
  });
}
