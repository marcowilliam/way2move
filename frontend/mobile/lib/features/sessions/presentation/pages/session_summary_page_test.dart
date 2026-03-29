import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/exercises/presentation/providers/exercise_providers.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/presentation/pages/session_summary_page.dart';
import 'package:way2move/features/sessions/presentation/providers/session_providers.dart';

// ── Fake notifiers ────────────────────────────────────────────────────────────

class _FakeSessionHistoryNotifier extends SessionHistoryNotifier {
  final List<Session> initial;
  _FakeSessionHistoryNotifier(this.initial);

  @override
  Future<List<Session>> build() async {
    state = AsyncData(initial);
    return initial;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(String sessionId, List<Session> history) {
  final router = GoRouter(
    initialLocation: '/session/summary/$sessionId',
    routes: [
      GoRoute(
        path: '/session/summary/:id',
        builder: (_, state) =>
            SessionSummaryPage(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sessionHistoryProvider.overrideWith(
        () => _FakeSessionHistoryNotifier(history),
      ),
      exerciseListProvider.overrideWith((_) async => []),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  const tBlock = ExerciseBlock(
    exerciseId: 'ex_deadbug',
    plannedSets: 3,
    plannedReps: '10',
    actualSets: [
      SetEntry(setNumber: 1, reps: 10, completed: true),
      SetEntry(setNumber: 2, reps: 10, completed: true),
    ],
    rpe: 7,
  );

  final tSession = Session(
    id: 's1',
    userId: 'user1',
    focus: 'Core & Breathing',
    date: DateTime(2026, 3, 30),
    status: SessionStatus.completed,
    exerciseBlocks: [tBlock],
    notes: 'Felt strong today',
    durationMinutes: 40,
  );

  group('SessionSummaryPage', () {
    testWidgets('shows summary page key', (tester) async {
      await tester.pumpWidget(_wrap('s1', [tSession]));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.sessionSummaryPage), findsOneWidget);
    });

    testWidgets('shows Workout Complete headline', (tester) async {
      await tester.pumpWidget(_wrap('s1', [tSession]));
      await tester.pumpAndSettle();

      expect(find.text('Workout Complete!'), findsOneWidget);
    });

    testWidgets('shows duration stat when available', (tester) async {
      await tester.pumpWidget(_wrap('s1', [tSession]));
      await tester.pumpAndSettle();

      expect(find.text('40m'), findsOneWidget);
    });

    testWidgets('shows session notes when present', (tester) async {
      await tester.pumpWidget(_wrap('s1', [tSession]));
      await tester.pumpAndSettle();

      expect(find.text('Felt strong today'), findsOneWidget);
    });

    testWidgets('shows done button that navigates to home', (tester) async {
      await tester.pumpWidget(_wrap('s1', [tSession]));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.sessionDoneButton), findsOneWidget);
    });
  });
}
