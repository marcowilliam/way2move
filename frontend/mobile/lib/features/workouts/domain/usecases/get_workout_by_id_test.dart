import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/workouts/domain/entities/workout.dart';
import 'package:way2move/features/workouts/domain/entities/workout_enums.dart';
import 'package:way2move/features/workouts/domain/repositories/workout_repository.dart';
import 'package:way2move/features/workouts/domain/usecases/get_workout_by_id.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late MockWorkoutRepository mockRepo;
  late GetWorkoutById getWorkoutById;

  const tWorkout = Workout(
    id: 'day-a',
    userId: 'user1',
    name: 'DAY A',
    kind: WorkoutKind.abcde,
  );

  setUp(() {
    mockRepo = MockWorkoutRepository();
    getWorkoutById = GetWorkoutById(mockRepo);
  });

  test('delegates to repository.getWorkoutById', () async {
    when(() => mockRepo.getWorkoutById('day-a'))
        .thenAnswer((_) async => const Right(tWorkout));

    final result = await getWorkoutById('day-a');

    expect(result, const Right<AppFailure, Workout>(tWorkout));
    verify(() => mockRepo.getWorkoutById('day-a')).called(1);
  });

  test('returns Left on repository failure', () async {
    when(() => mockRepo.getWorkoutById(any()))
        .thenAnswer((_) async => const Left(ServerFailure('not-found')));

    final result = await getWorkoutById('missing');

    expect(result.isLeft(), true);
  });
}
