import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/domain/repositories/goal_repository.dart';
import 'package:way2move/features/goals/domain/usecases/mark_goal_achieved.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockGoalRepository mockRepo;
  late MarkGoalAchieved markGoalAchieved;

  setUp(() {
    mockRepo = MockGoalRepository();
    markGoalAchieved = MarkGoalAchieved(mockRepo);
  });

  group('MarkGoalAchieved', () {
    test('returns achieved Goal on success', () async {
      final achievedGoal = Goal(
        id: 'g1',
        userId: 'u1',
        name: 'Hip stability',
        category: GoalCategory.stability,
        targetMetric: 'clamshell reps',
        targetValue: 20,
        currentValue: 20,
        unit: 'reps',
        source: GoalSource.suggested,
        status: GoalStatus.achieved,
        achievedAt: DateTime(2025, 1, 1),
      );
      when(() => mockRepo.markAchieved('g1'))
          .thenAnswer((_) async => Right(achievedGoal));

      final result = await markGoalAchieved('g1');

      expect(result.isRight(), true);
      expect(result.getRight().toNullable()?.status, GoalStatus.achieved);
      expect(result.getRight().toNullable()?.achievedAt, isNotNull);
      verify(() => mockRepo.markAchieved('g1')).called(1);
    });

    test('returns NotFoundFailure when goal does not exist', () async {
      when(() => mockRepo.markAchieved('nonexistent'))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await markGoalAchieved('nonexistent');

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
    });

    test('returns ServerFailure on backend error', () async {
      when(() => mockRepo.markAchieved('g1'))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await markGoalAchieved('g1');

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
