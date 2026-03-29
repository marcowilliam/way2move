import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/exercises/domain/entities/exercise.dart';
import 'package:way2move/features/exercises/presentation/providers/exercise_providers.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/presentation/pages/session_view.dart';
import 'package:way2move/features/sessions/presentation/providers/session_providers.dart';

// ── Fake notifiers ─────────────────────────────────────────────────────────────

class _FakeActiveSessionNotifier extends ActiveSessionNotifier {
  final AsyncValue<ActiveSessionState?> initial;
  _FakeActiveSessionNotifier(this.initial);

  @override
  Future<ActiveSessionState?> build() async {
    if (initial.isLoading) {
      // Never complete so the provider stays in loading state
      return Completer<ActiveSessionState?>().future;
    }
    state = initial;
    return initial.valueOrNull;
  }
}

// ── Test helpers ───────────────────────────────────────────────────────────────

Widget _wrap(
  Widget child, {
  required AsyncValue<ActiveSessionState?> activeState,
  List<Exercise> exercises = const [],
}) {
  final router = GoRouter(
    initialLocation: '/session/active',
    routes: [
      GoRoute(
        path: '/session/active',
        builder: (_, __) => child,
      ),
      GoRoute(
        path: '/session/summary/:id',
        builder: (_, __) => const Scaffold(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      activeSessionProvider.overrideWith(
        () => _FakeActiveSessionNotifier(activeState),
      ),
      exerciseListProvider.overrideWith((_) async => exercises),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  const tBlock = ExerciseBlock(
    exerciseId: 'ex_deadbug',
    plannedSets: 3,
    plannedReps: '10',
  );

  const tExercise = Exercise(
    id: 'ex_deadbug',
    name: 'Dead Bug',
    description: 'Core stability exercise',
    videoUrl: '',
    sportTags: [],
    patternTags: [],
    regionTags: [],
    typeTags: [ExerciseType.stability],
    equipmentTags: [],
    difficulty: ExerciseDifficulty.beginner,
    progressionIds: [],
    regressionIds: [],
    cues: [],
  );

  final tSession = Session(
    id: 's1',
    userId: 'user1',
    focus: 'Core & Breathing',
    date: DateTime(2026, 3, 30),
    status: SessionStatus.inProgress,
    exerciseBlocks: const [tBlock],
  );

  group('SessionView', () {
    testWidgets('shows session_view key when active session loaded',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SessionView(),
          activeState: AsyncData(ActiveSessionState(session: tSession)),
          exercises: const [tExercise],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.sessionView), findsOneWidget);
    });

    testWidgets('complete button disabled when no sets recorded',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SessionView(),
          activeState: AsyncData(ActiveSessionState(session: tSession)),
          exercises: const [tExercise],
        ),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<FilledButton>(
        find.byKey(AppKeys.completeSessionButton),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('complete button enabled when at least one set recorded',
        (tester) async {
      const blockWithSet = ExerciseBlock(
        exerciseId: 'ex_deadbug',
        plannedSets: 3,
        plannedReps: '10',
        actualSets: [SetEntry(setNumber: 1, reps: 10, completed: true)],
      );
      final sessionWithWork = tSession.copyWith(
        exerciseBlocks: const [blockWithSet],
      );

      await tester.pumpWidget(
        _wrap(
          const SessionView(),
          activeState: AsyncData(ActiveSessionState(session: sessionWithWork)),
          exercises: const [tExercise],
        ),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<FilledButton>(
        find.byKey(AppKeys.completeSessionButton),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('shows loading indicator when active session is loading',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SessionView(),
          activeState: const AsyncLoading(),
          exercises: const [],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows focus title from session', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SessionView(),
          activeState: AsyncData(ActiveSessionState(session: tSession)),
          exercises: const [tExercise],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Core & Breathing'), findsOneWidget);
    });
  });
}
