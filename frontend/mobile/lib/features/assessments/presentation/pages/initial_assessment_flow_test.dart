import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';
import 'package:way2move/features/assessments/data/repositories/assessment_repository_impl.dart';
import 'package:way2move/features/assessments/presentation/pages/initial_assessment_flow.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

Widget _buildTestWidget({AssessmentRepository? repo}) {
  final mockRepo = repo ?? MockAssessmentRepository();
  return ProviderScope(
    overrides: [
      assessmentRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/assessment',
        routes: [
          GoRoute(
            path: '/assessment',
            builder: (_, __) => const InitialAssessmentFlow(),
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
  group('InitialAssessmentFlow', () {
    testWidgets('shows intro screen with Start Assessment button',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.assessmentFlow), findsOneWidget);
      expect(find.text('Movement Assessment'), findsOneWidget);
      expect(find.text('Start Assessment'), findsOneWidget);
    });

    testWidgets('tapping Start Assessment advances to occupation step',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Assessment'));
      await tester.pumpAndSettle();

      expect(find.text('Movement Assessment'), findsNothing);
      expect(find.textContaining('main occupation'), findsOneWidget);
    });

    testWidgets('Continue button is disabled until option is selected',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Assessment'));
      await tester.pumpAndSettle();

      // Find Continue button — should be opacity 0.4 (disabled)
      final filledButtons = find.byType(FilledButton);
      // The continue button exists but onPressed is null
      final button = tester.widget<FilledButton>(filledButtons.first);
      expect(button.onPressed, isNull);
    });

    testWidgets('selecting occupation enables Continue button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Assessment'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Desk / Office Work'));
      await tester.pump();

      final buttons = find.byType(FilledButton);
      final button = tester.widget<FilledButton>(buttons.last);
      expect(button.onPressed, isNotNull);
    });
  });
}
