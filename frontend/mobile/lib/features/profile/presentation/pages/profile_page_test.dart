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
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';
import 'package:way2move/features/profile/presentation/pages/profile_page.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthRepository extends Mock
    implements
        // ignore: avoid_implementing_value_types
        Object {}

final _profile = UserProfile(
  id: 'test-uid',
  name: 'Jane Athlete',
  email: 'jane@example.com',
  onboardingComplete: true,
  trainingGoal: TrainingGoal.mobility,
  createdAt: DateTime(2024),
);

Widget _buildPage({
  required MockSessionRepository sessionRepo,
  required MockGoalRepository goalRepo,
  required MockProfileRepository profileRepo,
  UserProfile? profile,
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
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (_, __) => const Scaffold(body: Text('profile edit')),
          ),
          GoRoute(
            path: '/programs',
            builder: (_, __) => const Scaffold(body: Text('programs')),
          ),
          GoRoute(
            path: '/assessment',
            builder: (_, __) => const Scaffold(body: Text('assessment')),
          ),
          GoRoute(
            path: '/assessment/history',
            builder: (_, __) =>
                const Scaffold(body: Text('assessment history')),
          ),
          GoRoute(
            path: '/compensations',
            builder: (_, __) => const Scaffold(body: Text('compensations')),
          ),
          GoRoute(
            path: '/goals',
            builder: (_, __) => const Scaffold(body: Text('goals')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const Scaffold(body: Text('onboarding')),
          ),
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
  });

  testWidgets('shows profile page key', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.profilePage), findsOneWidget);
  });

  testWidgets('shows user name in header', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.text('Jane Athlete'), findsOneWidget);
  });

  testWidgets('shows stats row with streak, sessions, goals', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.text('Day Streak'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
  });

  testWidgets('shows navigation tiles for training and movement sections',
      (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.text('My Program'), findsOneWidget);
    expect(find.text('Movement Assessment'), findsOneWidget);
    expect(find.text('Compensation Profile'), findsOneWidget);
  });

  testWidgets('shows sign out button', (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    // Sign out button may be below the fold — check full widget tree
    expect(
        find.byKey(AppKeys.signOutButton, skipOffstage: false), findsOneWidget);
  });

  testWidgets('does not show onboarding CTA when onboarding is complete',
      (tester) async {
    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo));
    await tester.pumpAndSettle();

    expect(find.text('Complete your setup'), findsNothing);
  });

  testWidgets('shows onboarding CTA when onboarding is not complete',
      (tester) async {
    final incompleteProfile = _profile.copyWith(onboardingComplete: false);
    when(() => profileRepo.watchProfile(any()))
        .thenAnswer((_) => Stream.value(incompleteProfile));
    when(() => profileRepo.getProfile(any()))
        .thenAnswer((_) async => Right(incompleteProfile));

    await tester.pumpWidget(_buildPage(
        sessionRepo: sessionRepo,
        goalRepo: goalRepo,
        profileRepo: profileRepo,
        profile: incompleteProfile));
    await tester.pumpAndSettle();

    expect(find.text('Complete your setup'), findsOneWidget);
  });
}
