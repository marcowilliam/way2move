import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:way2move/features/assessments/domain/entities/assessment.dart'
    show CompensationPattern;
import 'package:way2move/features/assessments/domain/entities/assessment_comparison_result.dart';
import 'package:way2move/features/assessments/domain/entities/detected_compensation.dart';
import 'compensation_improvement_card.dart';

void main() {
  group('CompensationImprovementCard', () {
    testWidgets('shows pattern name', (tester) async {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: CompensationSeverity.significant,
        afterSeverity: CompensationSeverity.mild,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompensationImprovementCard(change: change),
          ),
        ),
      );

      expect(find.textContaining('Knee Valgus'), findsOneWidget);
    });

    testWidgets('shows severity badges for before and after', (tester) async {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: CompensationSeverity.significant,
        afterSeverity: CompensationSeverity.mild,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompensationImprovementCard(change: change),
          ),
        ),
      );

      expect(find.text('Significant'), findsOneWidget);
      expect(find.text('Mild'), findsOneWidget);
    });

    testWidgets('shows "Resolved" badge when afterSeverity is null',
        (tester) async {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: CompensationSeverity.moderate,
        afterSeverity: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompensationImprovementCard(change: change),
          ),
        ),
      );

      expect(find.text('Resolved'), findsOneWidget);
    });

    testWidgets('shows "Not detected" badge when beforeSeverity is null',
        (tester) async {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: null,
        afterSeverity: CompensationSeverity.mild,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompensationImprovementCard(change: change),
          ),
        ),
      );

      expect(find.text('Not detected'), findsOneWidget);
    });

    testWidgets('shows check_circle icon for resolved pattern', (tester) async {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: CompensationSeverity.moderate,
        afterSeverity: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompensationImprovementCard(change: change),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows trending_up icon for worsened pattern', (tester) async {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: CompensationSeverity.mild,
        afterSeverity: CompensationSeverity.significant,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompensationImprovementCard(change: change),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });
  });
}
