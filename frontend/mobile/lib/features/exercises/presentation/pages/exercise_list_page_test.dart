import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/exercises/data/repositories/exercise_repository_impl.dart';
import 'package:way2move/features/exercises/domain/entities/exercise.dart';
import 'package:way2move/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:way2move/features/exercises/presentation/pages/exercise_list_page.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late MockExerciseRepository mockRepo;

  const tExercises = [
    Exercise(
      id: 'ex_deadbug',
      name: 'Dead Bug',
      description: 'Core stability exercise',
      difficulty: ExerciseDifficulty.beginner,
      typeTags: [ExerciseType.stability],
    ),
    Exercise(
      id: 'ex_bird_dog',
      name: 'Bird Dog',
      description: 'Quadruped stability',
      difficulty: ExerciseDifficulty.beginner,
    ),
  ];

  setUp(() {
    mockRepo = MockExerciseRepository();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(home: ExerciseListPage()),
    );
  }

  group('ExerciseListPage', () {
    testWidgets('shows list of exercises when data loads', (tester) async {
      when(() => mockRepo.getExercises())
          .thenAnswer((_) async => const Right(tExercises));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Dead Bug'), findsOneWidget);
      expect(find.text('Bird Dog'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      when(() => mockRepo.getExercises())
          .thenAnswer((_) async => const Right(tExercises));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(AppKeys.exerciseSearchField), findsOneWidget);
    });

    testWidgets('shows add exercise button', (tester) async {
      when(() => mockRepo.getExercises())
          .thenAnswer((_) async => const Right(tExercises));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(AppKeys.addExerciseButton), findsOneWidget);
    });

    testWidgets('shows empty state when no exercises', (tester) async {
      when(() => mockRepo.getExercises())
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('No exercises yet'), findsOneWidget);
    });

    testWidgets('filters exercises by search query', (tester) async {
      when(() => mockRepo.getExercises())
          .thenAnswer((_) async => const Right(tExercises));
      when(() => mockRepo.searchExercises('dead'))
          .thenAnswer((_) async => const Right([
                Exercise(
                  id: 'ex_deadbug',
                  name: 'Dead Bug',
                  description: 'Core stability exercise',
                  difficulty: ExerciseDifficulty.beginner,
                  typeTags: [ExerciseType.stability],
                ),
              ]));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(AppKeys.exerciseSearchField), 'dead');
      await tester.pumpAndSettle();

      verify(() => mockRepo.searchExercises('dead')).called(greaterThan(0));
    });
  });
}
