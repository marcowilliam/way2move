import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/exercises/domain/entities/exercise.dart';
import 'package:way2move/features/exercises/presentation/pages/exercise_detail_page.dart';
import 'package:way2move/features/exercises/presentation/providers/exercise_providers.dart';

void main() {
  const tExercise = Exercise(
    id: 'ex_deadbug',
    name: 'Dead Bug',
    description: 'Core stability exercise',
    videoUrl: '',
    difficulty: ExerciseDifficulty.beginner,
    typeTags: [ExerciseType.stability],
    regionTags: [BodyRegion.core],
    cues: ['Brace the ribs', 'Keep the low back flat'],
    progressionIds: [],
    regressionIds: [],
  );

  Widget wrap({Exercise? exercise}) {
    return ProviderScope(
      overrides: [
        exerciseDetailProvider('ex_deadbug').overrideWith((ref) async => exercise),
      ],
      child: const MaterialApp(
        home: ExerciseDetailPage(exerciseId: 'ex_deadbug'),
      ),
    );
  }

  group('ExerciseDetailPage', () {
    testWidgets('shows exercise name as headline', (tester) async {
      await tester.pumpWidget(wrap(exercise: tExercise));
      await tester.pumpAndSettle();

      expect(find.text('Dead Bug'), findsOneWidget);
      expect(find.byKey(AppKeys.exerciseDetailPage), findsOneWidget);
    });

    testWidgets('renders coaching cues section', (tester) async {
      await tester.pumpWidget(wrap(exercise: tExercise));
      await tester.pumpAndSettle();

      expect(find.text('Coaching cues'), findsOneWidget);
      expect(find.text('Brace the ribs'), findsOneWidget);
    });

    testWidgets('shows Add to session CTA', (tester) async {
      await tester.pumpWidget(wrap(exercise: tExercise));
      await tester.pumpAndSettle();

      expect(find.text('Add to session'), findsOneWidget);
    });

    testWidgets('shows not-found scaffold when exercise is null',
        (tester) async {
      await tester.pumpWidget(wrap(exercise: null));
      await tester.pumpAndSettle();

      expect(find.text('Exercise not found'), findsOneWidget);
    });
  });
}
