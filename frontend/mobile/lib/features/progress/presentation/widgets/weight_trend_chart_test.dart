import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/progress/domain/entities/weight_log.dart';
import 'package:way2move/features/progress/presentation/widgets/weight_trend_chart.dart';

void main() {
  Widget buildChart(List<WeightLog> logs) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: WeightTrendChart(logs: logs),
        ),
      ),
    );
  }

  group('WeightTrendChart', () {
    testWidgets('shows empty state when no logs', (tester) async {
      await tester.pumpWidget(buildChart([]));
      await tester.pump();

      expect(find.byKey(const Key('weight_trend_chart_empty')), findsOneWidget);
      expect(find.text('No weight data yet'), findsOneWidget);
    });

    testWidgets('renders chart with data', (tester) async {
      final logs = [
        WeightLog(
          id: '1',
          userId: 'u1',
          date: DateTime(2026, 3, 27),
          weight: 76.0,
          unit: WeightUnit.kg,
        ),
        WeightLog(
          id: '2',
          userId: 'u1',
          date: DateTime(2026, 3, 28),
          weight: 75.5,
          unit: WeightUnit.kg,
        ),
        WeightLog(
          id: '3',
          userId: 'u1',
          date: DateTime(2026, 3, 29),
          weight: 75.2,
          unit: WeightUnit.kg,
        ),
      ];

      await tester.pumpWidget(buildChart(logs));
      await tester.pump();

      expect(find.byKey(const Key('weight_trend_chart')), findsOneWidget);
      // Average is (76+75.5+75.2)/3 ≈ 75.6 — check average text is shown
      expect(find.textContaining('Avg:'), findsOneWidget);
    });

    testWidgets('shows average weight label with unit', (tester) async {
      final logs = [
        WeightLog(
          id: '1',
          userId: 'u1',
          date: DateTime(2026, 3, 29),
          weight: 80.0,
          unit: WeightUnit.kg,
        ),
      ];

      await tester.pumpWidget(buildChart(logs));
      await tester.pump();

      expect(find.textContaining('80.0 kg'), findsOneWidget);
    });
  });
}
