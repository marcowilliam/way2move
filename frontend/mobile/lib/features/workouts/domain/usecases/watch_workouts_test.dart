import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/workouts/domain/entities/workout.dart';
import 'package:way2move/features/workouts/domain/entities/workout_enums.dart';
import 'package:way2move/features/workouts/domain/repositories/workout_repository.dart';
import 'package:way2move/features/workouts/domain/usecases/watch_workouts.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late MockWorkoutRepository mockRepo;
  late WatchWorkouts watchWorkouts;

  const tWorkout = Workout(
    id: 'w1',
    userId: 'user1',
    name: 'Cranium',
    kind: WorkoutKind.snack,
  );

  setUp(() {
    mockRepo = MockWorkoutRepository();
    watchWorkouts = WatchWorkouts(mockRepo);
  });

  test('emits values from repository.watchWorkouts', () async {
    when(() => mockRepo.watchWorkouts('user1', kind: WorkoutKind.snack))
        .thenAnswer((_) => Stream.value([tWorkout]));

    final stream = watchWorkouts('user1', kind: WorkoutKind.snack);

    expect(await stream.first, [tWorkout]);
  });
}
