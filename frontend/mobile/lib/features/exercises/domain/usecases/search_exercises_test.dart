import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/exercises/domain/entities/exercise.dart';
import 'package:way2move/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:way2move/features/exercises/domain/usecases/search_exercises.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late MockExerciseRepository mockRepo;
  late SearchExercises searchExercises;

  const tDeadBug = Exercise(
    id: 'ex_deadbug',
    name: 'Dead Bug',
    description: 'Core stability exercise',
    difficulty: ExerciseDifficulty.beginner,
  );

  setUp(() {
    mockRepo = MockExerciseRepository();
    searchExercises = SearchExercises(mockRepo);
  });

  group('SearchExercises', () {
    test('returns matching exercises for query', () async {
      when(() => mockRepo.searchExercises(any()))
          .thenAnswer((_) async => const Right([tDeadBug]));

      final result = await searchExercises('dead');

      expect(result, const Right([tDeadBug]));
      verify(() => mockRepo.searchExercises('dead')).called(1);
    });

    test('returns empty list when nothing matches', () async {
      when(() => mockRepo.searchExercises(any()))
          .thenAnswer((_) async => const Right([]));

      final result = await searchExercises('xyznotexisting');

      expect(result, const Right(<Exercise>[]));
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.searchExercises(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await searchExercises('any');

      expect(result.isLeft(), true);
    });
  });
}
