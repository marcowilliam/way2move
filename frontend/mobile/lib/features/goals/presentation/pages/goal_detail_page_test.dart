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
import 'package:way2move/features/goals/presentation/pages/goal_detail_page.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

Goal _goal({
  String id = 'g1',
  GoalStatus status = GoalStatus.active,
  double current = 5,
  DateTime? achievedAt,
}) =>
    Goal(
      id: id,
      userId: 'test-uid',
      name: 'Hip Stability',
      description: 'Improve hip control',
      category: GoalCategory.stability,
      targetMetric: 'clamshell reps',
      targetValue: 20,
      currentValue: current,
      unit: 'reps',
      source: GoalSource.suggested,
      status: status,
      achievedAt: achievedAt,
    );

Widget _buildPage(MockGoalRepository mockRepo, String goalId) {
  return ProviderScope(
    overrides: [
      goalRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/goals/$goalId',
        routes: [
          GoRoute(
            path: '/goals/:goalId',
            builder: (_, state) =>
                GoalDetailPage(goalId: state.pathParameters['goalId']!),
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

  testWidgets('shows goal detail page key', (tester) async {
    final goal = _goal();
    when(() => mockRepo.getAll(any()))
        .thenAnswer((_) async => Right([goal]));

    await tester.pumpWidget(_buildPage(mockRepo, 'g1'));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.goalDetailPage), findsOneWidget);
  });

  testWidgets('shows goal name and target metric', (tester) async {
    final goal = _goal();
    when(() => mockRepo.getAll(any()))
        .thenAnswer((_) async => Right([goal]));

    await tester.pumpWidget(_buildPage(mockRepo, 'g1'));
    await tester.pumpAndSettle();

    expect(find.text('Hip Stability'), findsWidgets);
    expect(find.text('clamshell reps'), findsOneWidget);
  });

  testWidgets('shows mark achieved button for active goal', (tester) async {
    final goal = _goal();
    when(() => mockRepo.getAll(any()))
        .thenAnswer((_) async => Right([goal]));

    await tester.pumpWidget(_buildPage(mockRepo, 'g1'));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.goalMarkAchievedButton), findsOneWidget);
  });

  testWidgets('does not show mark achieved button for achieved goal',
      (tester) async {
    final goal = _goal(
      status: GoalStatus.achieved,
      current: 20,
      achievedAt: DateTime(2025, 1, 1),
    );
    when(() => mockRepo.getAll(any()))
        .thenAnswer((_) async => Right([goal]));

    await tester.pumpWidget(_buildPage(mockRepo, 'g1'));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.goalMarkAchievedButton), findsNothing);
  });

  testWidgets('shows not found text when goal id is missing', (tester) async {
    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_buildPage(mockRepo, 'nonexistent'));
    await tester.pumpAndSettle();

    expect(find.text('Goal not found'), findsOneWidget);
  });
}
