import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/calendar/presentation/pages/calendar_page.dart';
import 'package:way2move/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

Widget _buildPage(MockSessionRepository mockRepo) {
  return ProviderScope(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/calendar',
        routes: [
          GoRoute(
            path: '/calendar',
            builder: (_, __) => const CalendarPage(),
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

  testWidgets('shows calendar page key', (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.calendarPage), findsOneWidget);
  });

  testWidgets('shows month grid by default', (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.calendarMonthGrid), findsOneWidget);
  });

  testWidgets('tapping Week toggle switches to week strip', (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.calendarWeekToggle));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.calendarWeekStrip), findsOneWidget);
  });

  testWidgets('tapping Month toggle shows month grid again', (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    // Switch to week
    await tester.tap(find.byKey(AppKeys.calendarWeekToggle));
    await tester.pumpAndSettle();

    // Switch back to month
    await tester.tap(find.byKey(AppKeys.calendarMonthToggle));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.calendarMonthGrid), findsOneWidget);
  });

  testWidgets('month name is displayed in top bar', (tester) async {
    when(() => mockRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    // Some month name should be visible
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final found = months.any(
      (m) => tester.any(find.textContaining(m)),
    );
    expect(found, true);
  });
}
