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
import 'package:way2move/features/goals/presentation/pages/goal_setup_page.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

Widget _buildPage(MockGoalRepository mockRepo) {
  return ProviderScope(
    overrides: [
      goalRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/goals/setup',
        routes: [
          GoRoute(
            path: '/goals/setup',
            builder: (_, __) => const GoalSetupPage(),
          ),
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  late MockGoalRepository mockRepo;

  setUp(() {
    mockRepo = MockGoalRepository();
  });

  setUpAll(() {
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

  testWidgets('shows setup page with key', (tester) async {
    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepo.create(any())).thenAnswer(
      (_) async => const Right(Goal(
        id: 'g',
        userId: '',
        name: '',
        category: GoalCategory.general,
        targetMetric: '',
        targetValue: 0,
        unit: '',
        source: GoalSource.suggested,
      )),
    );

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.goalSetupPage), findsOneWidget);
  });

  testWidgets('shows suggested goal cards', (tester) async {
    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    // At least one suggested goal card should be visible
    expect(find.text('Correct forward head posture'), findsOneWidget);
  });

  testWidgets('Done button navigates to home', (tester) async {
    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.goalSetupDoneButton));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('tapping a goal card selects it and shows add button',
      (tester) async {
    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepo.create(any())).thenAnswer(
      (_) async => const Right(Goal(
        id: 'g',
        userId: '',
        name: '',
        category: GoalCategory.general,
        targetMetric: '',
        targetValue: 0,
        unit: '',
        source: GoalSource.suggested,
      )),
    );

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    // Tap first suggested goal to select it
    await tester.tap(find.text('Correct forward head posture'));
    await tester.pump();

    // Add X goals button should appear
    expect(find.text('Add 1 goal'), findsOneWidget);
  });
}
