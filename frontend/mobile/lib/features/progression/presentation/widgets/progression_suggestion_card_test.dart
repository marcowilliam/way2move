import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/presentation/providers/goal_providers.dart';
import 'package:way2move/features/progression/domain/entities/progression_suggestion.dart';
import 'package:way2move/features/progression/presentation/widgets/progression_suggestion_card.dart';

void main() {
  List<Override> baseOverrides() => [
        currentUserIdProvider.overrideWithValue(null),
        goalNotifierProvider.overrideWith(() => _FakeGoalNotifier()),
      ];

  Widget buildTestWidget({
    required ProgressionSuggestion suggestion,
    VoidCallback? onAccept,
    VoidCallback? onDismiss,
  }) {
    return ProviderScope(
      overrides: baseOverrides(),
      child: MaterialApp(
        home: Scaffold(
          body: ProgressionSuggestionCard(
            suggestion: suggestion,
            onAccept: onAccept,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
  }

  const progressionSuggestion = ProgressionSuggestion(
    exerciseId: 'ex1',
    exerciseName: 'Squat',
    action: ProgressionAction.increaseReps,
    newReps: 2,
    reason: 'You hit 3 sessions. Add 2 more reps.',
    type: SuggestionType.progression,
  );

  const deloadSuggestion = ProgressionSuggestion(
    exerciseId: 'ex1',
    exerciseName: 'Squat',
    action: ProgressionAction.deload,
    reason: 'Body signals suggest recovery is needed: low sleep quality.',
    type: SuggestionType.deload,
  );

  group('ProgressionSuggestionCard — progression', () {
    testWidgets('renders progression card with correct title', (tester) async {
      await tester
          .pumpWidget(buildTestWidget(suggestion: progressionSuggestion));
      await tester.pumpAndSettle();

      expect(find.text('Progression Suggestion'), findsOneWidget);
    });

    testWidgets('renders exercise name', (tester) async {
      await tester
          .pumpWidget(buildTestWidget(suggestion: progressionSuggestion));
      await tester.pumpAndSettle();

      expect(find.text('Squat'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows increaseReps action text', (tester) async {
      await tester
          .pumpWidget(buildTestWidget(suggestion: progressionSuggestion));
      await tester.pumpAndSettle();

      expect(find.text('Try adding 2 more reps next time'), findsOneWidget);
    });

    testWidgets('shows Accept and Dismiss buttons', (tester) async {
      await tester
          .pumpWidget(buildTestWidget(suggestion: progressionSuggestion));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.progressionAcceptButton), findsOneWidget);
      expect(find.byKey(AppKeys.progressionDismissButton), findsOneWidget);
    });

    testWidgets('Dismiss button fires onDismiss callback', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(buildTestWidget(
        suggestion: progressionSuggestion,
        onDismiss: () => dismissed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.progressionDismissButton));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('card has progression key', (tester) async {
      await tester
          .pumpWidget(buildTestWidget(suggestion: progressionSuggestion));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.progressionSuggestionCard), findsOneWidget);
    });
  });

  group('ProgressionSuggestionCard — deload', () {
    testWidgets('renders deload card with correct title', (tester) async {
      await tester.pumpWidget(buildTestWidget(suggestion: deloadSuggestion));
      await tester.pumpAndSettle();

      expect(find.text('Recovery Suggestion'), findsOneWidget);
    });

    testWidgets('shows deload action text', (tester) async {
      await tester.pumpWidget(buildTestWidget(suggestion: deloadSuggestion));
      await tester.pumpAndSettle();

      expect(
        find.text('Take it lighter this week — your body needs recovery'),
        findsOneWidget,
      );
    });

    testWidgets('card has deload key', (tester) async {
      await tester.pumpWidget(buildTestWidget(suggestion: deloadSuggestion));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.progressionDeloadCard), findsOneWidget);
    });

    testWidgets('shows Accept and Dismiss buttons for deload too',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(suggestion: deloadSuggestion));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.progressionAcceptButton), findsOneWidget);
      expect(find.byKey(AppKeys.progressionDismissButton), findsOneWidget);
    });
  });

  group('ProgressionSuggestionCard — increaseLoad action', () {
    testWidgets('shows increaseLoad action text', (tester) async {
      const loadSuggestion = ProgressionSuggestion(
        exerciseId: 'ex1',
        exerciseName: 'Deadlift',
        action: ProgressionAction.increaseLoad,
        newWeight: 2.5,
        reason: 'Strong consistency.',
        type: SuggestionType.progression,
      );
      await tester.pumpWidget(buildTestWidget(suggestion: loadSuggestion));
      await tester.pumpAndSettle();

      expect(find.text('Consider increasing weight by 2.5kg'), findsOneWidget);
    });
  });

  group('ProgressionSuggestionCard — advanceVariation action', () {
    testWidgets('shows advanceVariation action text', (tester) async {
      const variationSuggestion = ProgressionSuggestion(
        exerciseId: 'ex1',
        exerciseName: 'Push-up',
        action: ProgressionAction.advanceVariation,
        nextExerciseId: 'ex2',
        reason: 'Time to advance.',
        type: SuggestionType.progression,
      );
      await tester.pumpWidget(buildTestWidget(suggestion: variationSuggestion));
      await tester.pumpAndSettle();

      expect(find.text("You're ready for the next level"), findsOneWidget);
    });
  });
}

class _FakeGoalNotifier extends AsyncNotifier<List<Goal>>
    implements GoalNotifier {
  @override
  Future<List<Goal>> build() async => [];

  @override
  Future<Either<AppFailure, Goal>> createGoal(Goal goal) async =>
      throw UnimplementedError();

  @override
  Future<Either<AppFailure, Goal>> updateGoal(Goal goal) async => Right(goal);

  @override
  Future<Either<AppFailure, Goal>> markAchieved(String goalId) async =>
      throw UnimplementedError();
}
