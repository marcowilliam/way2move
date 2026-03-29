import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/domain/repositories/goal_repository.dart';
import 'package:way2move/features/goals/presentation/widgets/add_goal_dialog.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

Widget _buildDialog(MockGoalRepository mockRepo) {
  return ProviderScope(
    overrides: [
      goalRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AddGoalDialog(userId: 'test-uid')),
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

  testWidgets('shows dialog with key', (tester) async {
    await tester.pumpWidget(_buildDialog(mockRepo));
    await tester.pump();

    expect(find.byKey(AppKeys.addGoalDialog), findsOneWidget);
  });

  testWidgets('shows name field and save button', (tester) async {
    await tester.pumpWidget(_buildDialog(mockRepo));
    await tester.pump();

    expect(find.byKey(AppKeys.goalNameField), findsOneWidget);
    expect(find.byKey(AppKeys.goalSaveButton), findsOneWidget);
  });

  testWidgets('shows validation error when name is empty', (tester) async {
    await tester.pumpWidget(_buildDialog(mockRepo));
    await tester.pump();

    await tester.tap(find.byKey(AppKeys.goalSaveButton));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('calls repository create when form is valid', (tester) async {
    const createdGoal = Goal(
      id: 'g1',
      userId: 'test-uid',
      name: 'Hip Stability',
      category: GoalCategory.stability,
      targetMetric: 'reps',
      targetValue: 20,
      unit: 'reps',
      source: GoalSource.manual,
    );

    when(() => mockRepo.getAll(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepo.create(any()))
        .thenAnswer((_) async => const Right(createdGoal));

    await tester.pumpWidget(_buildDialog(mockRepo));
    await tester.pump();

    await tester.enterText(find.byKey(AppKeys.goalNameField), 'Hip Stability');
    await tester.enterText(find.byKey(AppKeys.goalTargetValueField), '20');
    await tester.enterText(find.byKey(AppKeys.goalUnitField), 'reps');

    // Enter metric field
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Metric').first,
      'clamshell reps',
    );

    await tester.tap(find.byKey(AppKeys.goalSaveButton));
    await tester.pumpAndSettle();

    verify(() => mockRepo.create(any())).called(1);
  });

  testWidgets('shows category choice chips', (tester) async {
    await tester.pumpWidget(_buildDialog(mockRepo));
    await tester.pump();

    expect(find.text('Mobility'), findsOneWidget);
    expect(find.text('Stability'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
  });
}
