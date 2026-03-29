import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/calendar/presentation/widgets/day_sessions_sheet.dart';
import 'package:way2move/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

Session _session({
  String focus = 'Mobility',
  SessionStatus status = SessionStatus.completed,
  int? durationMinutes,
}) =>
    Session(
      id: 's1',
      userId: 'test-uid',
      date: DateTime(2026, 3, 15),
      status: status,
      exerciseBlocks: const [],
      focus: focus,
      durationMinutes: durationMinutes,
    );

Widget _buildSheet(
  MockSessionRepository mockRepo,
  DateTime day,
) {
  return ProviderScope(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, __) => Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showDaySessionsSheet(ctx, day),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/session/standalone',
            builder: (_, __) =>
                const Scaffold(body: Text('Standalone Session')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  late MockSessionRepository mockRepo;

  setUp(() {
    mockRepo = MockSessionRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      Session(
        id: '',
        userId: '',
        date: DateTime.now(),
        status: SessionStatus.planned,
        exerciseBlocks: const [],
      ),
    );
  });

  testWidgets('shows day sessions sheet key when opened', (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    final day = DateTime(2026, 3, 15);
    await tester.pumpWidget(_buildSheet(mockRepo, day));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.daySessionsSheet), findsOneWidget);
  });

  testWidgets('shows empty state when no sessions for day', (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    final day = DateTime(2026, 3, 15);
    await tester.pumpWidget(_buildSheet(mockRepo, day));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('No sessions'), findsOneWidget);
  });

  testWidgets('shows Start New Session button', (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    final day = DateTime.now();
    await tester.pumpWidget(_buildSheet(mockRepo, day));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.startNewSessionButton), findsOneWidget);
  });

  testWidgets('shows sessions for the day', (tester) async {
    final day = DateTime(2026, 3, 15);
    final session = _session(focus: 'Mobility Training', durationMinutes: 30);

    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => Right([session]));

    await tester.pumpWidget(_buildSheet(mockRepo, day));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Mobility Training'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
  });

  testWidgets('tapping Start New Session navigates to standalone session',
      (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    final day = DateTime.now();
    await tester.pumpWidget(_buildSheet(mockRepo, day));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.startNewSessionButton));
    await tester.pumpAndSettle();

    expect(find.text('Standalone Session'), findsOneWidget);
  });
}
