import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/exercises/domain/entities/exercise.dart';
import 'package:way2move/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:way2move/features/exercises/domain/usecases/get_exercises.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late MockExerciseRepository mockRepo;
  late GetExercises getExercises;

  final tExercises = [
    const Exercise(
      id: 'ex_deadbug',
      name: 'Dead Bug',
      description: 'Core stability exercise',
      difficulty: ExerciseDifficulty.beginner,
      typeTags: [ExerciseType.stability],
      regionTags: [BodyRegion.core],
    ),
    const Exercise(
      id: 'ex_hiphinge',
      name: 'Hip Hinge',
      description: 'Fundamental movement pattern',
      difficulty: ExerciseDifficulty.beginner,
      typeTags: [ExerciseType.mobility],
      patternTags: [MovementPattern.hinge],
    ),
  ];

  setUp(() {
    mockRepo = MockExerciseRepository();
    getExercises = GetExercises(mockRepo);
  });

  group('GetExercises', () {
    test('returns list of exercises on success', () async {
      when(() => mockRepo.getExercises())
          .thenAnswer((_) async => Right(tExercises));

      final result = await getExercises();

      expect(result, Right(tExercises));
      verify(() => mockRepo.getExercises()).called(1);
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.getExercises())
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getExercises();

      expect(result.isLeft(), true);
    });

    test('returns empty list when no exercises exist', () async {
      when(() => mockRepo.getExercises())
          .thenAnswer((_) async => const Right([]));

      final result = await getExercises();

      expect(result, const Right(<Exercise>[]));
    });
  });
}
