import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
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

class MockSessionRepository extends Mock implements SessionRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

final _profile = UserProfile(
  id: 'test-uid',
  name: 'Test User',
  email: 'test@example.com',
  onboardingComplete: true,
  createdAt: DateTime(2024),
);

Session _session({
  String id = 's1',
  SessionStatus status = SessionStatus.planned,
  String? focus,
}) =>
    Session(
      id: id,
      userId: 'test-uid',
      date: DateTime.now(),
      status: status,
      exerciseBlocks: const [],
      focus: focus,
    );

Goal _goal(String id) => Goal(
      id: id,
      userId: 'test-uid',
      name: 'Goal $id',
      category: GoalCategory.mobility,
      targetMetric: 'reps',
      targetValue: 20,
      currentValue: 10,
      unit: 'reps',
      source: GoalSource.suggested,
      status: GoalStatus.active,
    );

Widget _buildPage({
  required MockSessionRepository sessionRepo,
  required MockGoalRepository goalRepo,
  required MockProfileRepository profileRepo,
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('test-uid'),
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
              path: '/session/standalone',
              builder: (_, __) => const Scaffold(body: Text('standalone'))),
          GoRoute(
              path: '/session/active',
              builder: (_, __) => const Scaffold(body: Text('active'))),
          GoRoute(
              path: '/assessment',
              builder: (_, __) => const Scaffold(body: Text('assessment'))),
          GoRoute(
              path: '/programs',
              builder: (_, __) => const Scaffold(body: Text('programs'))),
          GoRoute(
              path: '/exercises',
              builder: (_, __) => const Scaffold(body: Text('exercises'))),
          GoRoute(
              path: '/goals',
              builder: (_, __) => const Scaffold(body: Text('goals'))),
          GoRoute(
              path: '/goals/:goalId',
              builder: (_, state) => Scaffold(
                  body: Text('goal-${state.pathParameters['goalId']}'))),
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
        ],
      ),
    ),
  );
}

void main() {
  late MockSessionRepository sessionRepo;
  late MockGoalRepository goalRepo;
  late MockProfileRepository profileRepo;

  setUp(() {
    sessionRepo = MockSessionRepository();
    goalRepo = MockGoalRepository();
    profileRepo = MockProfileRepository();

    // Default stubs
    when(() => sessionRepo.watchSessionsByDate(any(), any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => sessionRepo.getSessionHistory(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => goalRepo.getByStatus(any(), any()))
        .thenAnswer((_) async => const Right([]));
    when(() => profileRepo.watchProfile(any()))
        .thenAnswer((_) => Stream.value(_profile));
    when(() => profileRepo.getProfile(any()))
        .thenAnswer((_) async => Right(_profile));
  });

  setUpAll(() {
    registerFallbackValue(GoalStatus.active);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(
      const Goal(
        id: '',
        userId: '',
        name: '',
        category: GoalCategory.general,
        targetMetric: '',
        targetValue: 0,
        unit: '',
        source: GoalSource.manual,
      ),
    );
  });

  testWidgets('shows home screen key', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.homeScreen), findsOneWidget);
  });

  testWidgets('shows greeting with user name', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Test'), findsWidgets);
  });

  testWidgets('shows "No session today" card when no sessions', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.text('No session today'), findsOneWidget);
  });

  testWidgets('shows planned session card when session is planned',
      (tester) async {
    final sessions = [_session(focus: 'Mobility Flow')];
    when(() => sessionRepo.watchSessionsByDate(any(), any()))
        .thenAnswer((_) => Stream.value(sessions));

    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.text('Mobility Flow'), findsOneWidget);
    expect(find.text('Start Session'), findsWidgets);
  });

  testWidgets('shows completed card when session is done today',
      (tester) async {
    final sessions = [_session(status: SessionStatus.completed, focus: 'Core')];
    when(() => sessionRepo.watchSessionsByDate(any(), any()))
        .thenAnswer((_) => Stream.value(sessions));

    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.text('Great work today!'), findsOneWidget);
  });

  testWidgets('shows quick action tiles', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    // Scroll down to reveal sections below the monthly heat map.
    await tester.drag(
        find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('New Session'), findsOneWidget);
    expect(find.text('Assessment'), findsOneWidget);
    expect(find.text('My Program'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
  });

  testWidgets('shows track today tiles', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    await tester.drag(
        find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.trackTodayGrid), findsOneWidget);
    expect(find.byKey(AppKeys.quickActionLogJournal), findsOneWidget);
    expect(find.byKey(AppKeys.quickActionLogMeal), findsOneWidget);
    expect(find.byKey(AppKeys.quickActionLogSleep), findsOneWidget);
    expect(find.byKey(AppKeys.quickActionProgressPhoto), findsOneWidget);
  });

  testWidgets('shows goal progress cards when goals exist', (tester) async {
    final goals = [_goal('g1'), _goal('g2')];
    when(() => goalRepo.getByStatus(any(), any()))
        .thenAnswer((_) async => Right(goals));

    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    await tester.drag(
        find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Active Goals'), findsOneWidget);
    expect(find.text('Goal g1'), findsOneWidget);
  });

  testWidgets('shows no goals CTA when goals list is empty', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    await tester.drag(
        find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('No active goals'), findsOneWidget);
  });
}
