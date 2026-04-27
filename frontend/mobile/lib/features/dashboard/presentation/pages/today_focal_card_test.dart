import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/domain/repositories/goal_repository.dart';
import 'package:way2move/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:way2move/features/profile/domain/entities/user_profile.dart';
import 'package:way2move/features/profile/domain/repositories/profile_repository.dart';
import 'package:way2move/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';
import 'package:way2move/features/dashboard/presentation/pages/home_page.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockGoalRepository extends Mock implements GoalRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

final _profile = UserProfile(
  id: 'u1',
  name: 'Marco',
  email: 'marco@example.com',
  onboardingComplete: true,
  createdAt: DateTime(2024),
);

Session _today({SessionStatus status = SessionStatus.planned, String? focus}) =>
    Session(
      id: 's-${status.name}',
      userId: 'u1',
      date: DateTime.now(),
      status: status,
      exerciseBlocks: const [],
      focus: focus,
    );

Session _yesterday({SessionStatus status = SessionStatus.planned}) => Session(
      id: 's-y-${status.name}',
      userId: 'u1',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: status,
      exerciseBlocks: const [],
    );

Widget _build({
  required _MockSessionRepository sessionRepo,
  required _MockGoalRepository goalRepo,
  required _MockProfileRepository profileRepo,
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('u1'),
      sessionRepositoryProvider.overrideWithValue(sessionRepo),
      goalRepositoryProvider.overrideWithValue(goalRepo),
      profileRepositoryProvider.overrideWithValue(profileRepo),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(
              path: '/session/active',
              builder: (_, __) => const Scaffold(body: Text('active'))),
          GoRoute(
              path: '/session/standalone',
              builder: (_, __) => const Scaffold(body: Text('standalone'))),
          GoRoute(
              path: '/journal/entry',
              builder: (_, __) => const Scaffold(body: Text('journal'))),
          GoRoute(
              path: '/nutrition/log',
              builder: (_, __) => const Scaffold(body: Text('meal'))),
          GoRoute(
              path: '/sleep',
              builder: (_, __) => const Scaffold(body: Text('sleep'))),
          GoRoute(
              path: '/progress/capture',
              builder: (_, __) => const Scaffold(body: Text('photo'))),
          GoRoute(
              path: '/assessment',
              builder: (_, __) => const Scaffold(body: Text('assessment'))),
          GoRoute(
              path: '/goals',
              builder: (_, __) => const Scaffold(body: Text('goals'))),
        ],
      ),
    ),
  );
}

void main() {
  late _MockSessionRepository sessionRepo;
  late _MockGoalRepository goalRepo;
  late _MockProfileRepository profileRepo;

  setUpAll(() {
    registerFallbackValue(GoalStatus.active);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    sessionRepo = _MockSessionRepository();
    goalRepo = _MockGoalRepository();
    profileRepo = _MockProfileRepository();

    when(() => goalRepo.getByStatus(any(), any()))
        .thenAnswer((_) async => const Right([]));
    when(() => profileRepo.watchProfile(any()))
        .thenAnswer((_) => Stream.value(_profile));
    when(() => profileRepo.getProfile(any()))
        .thenAnswer((_) async => Right(_profile));
    // Default to no history (no streak, no missed yesterday).
    when(() => sessionRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));
  });

  group('TodayFocalCard', () {
    testWidgets('active state shows Continue Session CTA', (tester) async {
      when(() => sessionRepo.watchSessionsByDate(any(), any())).thenAnswer(
        (_) => Stream.value(
          [_today(status: SessionStatus.inProgress, focus: 'Hip mobility')],
        ),
      );

      await tester.pumpWidget(_build(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Hip mobility'), findsOneWidget);
      expect(find.text('Continue Session'), findsOneWidget);
    });

    testWidgets('planned state shows focus + Start Session CTA',
        (tester) async {
      when(() => sessionRepo.watchSessionsByDate(any(), any())).thenAnswer(
        (_) => Stream.value(
          [_today(status: SessionStatus.planned, focus: 'Posterior chain')],
        ),
      );

      await tester.pumpWidget(_build(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text("Today's session"), findsOneWidget);
      expect(find.text('Posterior chain'), findsOneWidget);
      expect(find.text('Start Session'), findsOneWidget);
    });

    testWidgets('completed state shows Great work message', (tester) async {
      when(() => sessionRepo.watchSessionsByDate(any(), any())).thenAnswer(
        (_) => Stream.value(
          [_today(status: SessionStatus.completed, focus: 'Core')],
        ),
      );

      await tester.pumpWidget(_build(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Great work today!'), findsOneWidget);
      expect(find.text('Core completed'), findsOneWidget);
    });

    testWidgets(
        'no-session state shows missed-yesterday banner when applicable',
        (tester) async {
      when(() => sessionRepo.watchSessionsByDate(any(), any()))
          .thenAnswer((_) => Stream.value([]));
      // Yesterday had a planned session that wasn't completed → missed.
      when(() => sessionRepo.getSessionHistory(any())).thenAnswer(
        (_) async => Right([_yesterday()]),
      );

      await tester.pumpWidget(_build(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No session today'), findsOneWidget);
      expect(
        find.text('Back on track — every session counts.'),
        findsOneWidget,
      );
      expect(find.text('Start Session'), findsOneWidget);
    });

    testWidgets('no-session state without missed banner on a clean rest day',
        (tester) async {
      when(() => sessionRepo.watchSessionsByDate(any(), any()))
          .thenAnswer((_) => Stream.value([]));
      // History contains a completed yesterday → no missed banner.
      when(() => sessionRepo.getSessionHistory(any())).thenAnswer(
        (_) async => Right([_yesterday(status: SessionStatus.completed)]),
      );

      await tester.pumpWidget(_build(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No session today'), findsOneWidget);
      expect(
        find.text('Back on track — every session counts.'),
        findsNothing,
      );
    });
  });
}
