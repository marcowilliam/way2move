import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:way2move/features/assessments/domain/entities/assessment_comparison_result.dart';
import 'package:way2move/features/assessments/domain/entities/compensation_report.dart';
import 'movement_score_chart.dart';

AssessmentSnapshot _makeSnapshot({
  required String id,
  required DateTime date,
}) {
  return AssessmentSnapshot(
    assessmentId: id,
    assessmentDate: date,
    report: CompensationReport(
      assessmentId: id,
      userId: 'u1',
      detections: const [],
      generatedAt: date,
    ),
    videoAnalyses: const [],
  );
}

void main() {
  group('MovementScoreChart', () {
    late AssessmentComparisonResult comparison;

    setUp(() {
      comparison = AssessmentComparisonResult(
        initial: _makeSnapshot(id: 'a1', date: DateTime(2024, 1, 1)),
        reAssessment: _makeSnapshot(id: 'a2', date: DateTime(2024, 6, 1)),
      );
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovementScoreChart(comparison: comparison),
          ),
        ),
      );

      // Trigger initial animation frame
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows Initial and Re-Assessment legend labels',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovementScoreChart(comparison: comparison),
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);
      expect(find.text('Re-Assessment'), findsOneWidget);
    });

    testWidgets('animation completes without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovementScoreChart(comparison: comparison),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a bar group for each screening movement',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: MovementScoreChart(comparison: comparison),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // There should be labels for each movement
      expect(find.textContaining('Squat'), findsOneWidget);
      expect(find.textContaining('Stance'), findsOneWidget);
    });
  });
}
