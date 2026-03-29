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
import 'package:way2move/features/goals/presentation/pages/goal_list_page.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

Goal _goal(String id, {GoalStatus status = GoalStatus.active}) => Goal(
      id: id,
      userId: 'test-uid',
      name: 'Goal $id',
      category: GoalCategory.stability,
      targetMetric: 'reps',
      targetValue: 20,
      currentValue: 5,
      unit: 'reps',
      source: GoalSource.suggested,
      status: status,
    );

Widget _buildPage(MockGoalRepository mockRepo) {
  return ProviderScope(
    overrides: [
      goalRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/goals',
        routes: [
          GoRoute(
            path: '/goals',
            builder: (_, __) => const GoalListPage(),
            routes: [
              GoRoute(
                path: ':goalId',
                builder: (_, state) => Scaffold(
                  body: Text('Detail: ${state.pathParameters['goalId']}'),
                ),
              ),
            ],
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

  testWidgets('shows goal list page key', (tester) async {
    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.goalListPage), findsOneWidget);
  });

  testWidgets('shows empty state when no goals', (tester) async {
    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    expect(find.text('No goals yet'), findsOneWidget);
  });

  testWidgets('shows goal cards when goals are present', (tester) async {
    final goals = [_goal('g1'), _goal('g2')];
    when(() => mockRepo.getAll(any()))
        .thenAnswer((_) async => Right(goals));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    expect(find.text('Goal g1'), findsOneWidget);
    expect(find.text('Goal g2'), findsOneWidget);
  });

  testWidgets('shows FAB add button', (tester) async {
    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.goalAddButton), findsOneWidget);
  });

  testWidgets('tapping a goal card navigates to detail page', (tester) async {
    final goals = [_goal('g1')];
    when(() => mockRepo.getAll(any()))
        .thenAnswer((_) async => Right(goals));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Goal g1'));
    await tester.pumpAndSettle();

    expect(find.text('Detail: g1'), findsOneWidget);
  });
}
