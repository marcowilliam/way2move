import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/workouts/domain/entities/workout.dart';
import 'package:way2move/features/workouts/domain/entities/workout_enums.dart';
import 'package:way2move/features/workouts/domain/repositories/workout_repository.dart';
import 'package:way2move/features/workouts/domain/usecases/get_workouts.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late MockWorkoutRepository mockRepo;
  late GetWorkouts getWorkouts;

  const tUserId = 'user1';
  const tDayA = Workout(
    id: 'day-a',
    userId: tUserId,
    name: 'DAY A — Anterior Chain',
    kind: WorkoutKind.abcde,
  );
  const tCranium = Workout(
    id: 'cranium',
    userId: tUserId,
    name: 'Cranium routine',
    kind: WorkoutKind.snack,
  );

  setUp(() {
    mockRepo = MockWorkoutRepository();
    getWorkouts = GetWorkouts(mockRepo);
  });

  group('GetWorkouts', () {
    test('returns all workouts for user when no kind filter given', () async {
      when(() => mockRepo.getWorkouts(tUserId, kind: null))
          .thenAnswer((_) async => const Right([tDayA, tCranium]));

      final result = await getWorkouts(tUserId);

      expect(result.isRight(), true);
      expect(result.getRight().toNullable(), equals([tDayA, tCranium]));
      verify(() => mockRepo.getWorkouts(tUserId, kind: null)).called(1);
    });

    test('passes kind filter through to the repository', () async {
      when(() => mockRepo.getWorkouts(tUserId, kind: WorkoutKind.snack))
          .thenAnswer((_) async => const Right([tCranium]));

      final result = await getWorkouts(tUserId, kind: WorkoutKind.snack);

      expect(result.getRight().toNullable(), equals([tCranium]));
      verify(() => mockRepo.getWorkouts(tUserId, kind: WorkoutKind.snack))
          .called(1);
    });

    test('propagates ServerFailure from the repository', () async {
      when(() => mockRepo.getWorkouts(tUserId, kind: null))
          .thenAnswer((_) async => const Left(ServerFailure('firestore-down')));

      final result = await getWorkouts(tUserId);

      expect(result.isLeft(), true);
    });
  });
}
