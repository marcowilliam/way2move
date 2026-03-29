import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/domain/repositories/goal_repository.dart';
import 'package:way2move/features/goals/domain/usecases/create_goal.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

Goal _testGoal({String id = 'g1'}) => Goal(
      id: id,
      userId: 'u1',
      name: 'Hip stability',
      category: GoalCategory.stability,
      targetMetric: 'clamshell reps',
      targetValue: 20,
      unit: 'reps',
      source: GoalSource.suggested,
    );

void main() {
  late MockGoalRepository mockRepo;
  late CreateGoal createGoal;

  setUp(() {
    mockRepo = MockGoalRepository();
    createGoal = CreateGoal(mockRepo);
  });

  group('CreateGoal', () {
    test('returns Goal on success', () async {
      final goal = _testGoal();
      when(() => mockRepo.create(goal)).thenAnswer((_) async => Right(goal));

      final result = await createGoal(goal);

      expect(result, Right(goal));
      verify(() => mockRepo.create(goal)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      final goal = _testGoal();
      when(() => mockRepo.create(goal))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await createGoal(goal);

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
