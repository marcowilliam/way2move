import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/sleep/domain/entities/sleep_log.dart';
import 'package:way2move/features/sleep/presentation/widgets/sleep_history_chart.dart';

SleepLog _log(String id, {int quality = 4, int daysAgo = 0}) => SleepLog(
      id: id,
      userId: 'u1',
      bedTime: DateTime.now().subtract(Duration(days: daysAgo, hours: 8)),
      wakeTime: DateTime.now().subtract(Duration(days: daysAgo)),
      quality: quality,
      date: DateTime.now().subtract(Duration(days: daysAgo)),
    );

Widget _buildChart(List<SleepLog> logs) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SleepHistoryChart(logs: logs),
      ),
    ),
  );
}

void main() {
  testWidgets('renders chart key', (tester) async {
    await tester.pumpWidget(_buildChart([]));
    await tester.pump();

    expect(find.byKey(AppKeys.sleepHistoryChart), findsOneWidget);
  });

  testWidgets('shows empty state when no logs provided', (tester) async {
    await tester.pumpWidget(_buildChart([]));
    await tester.pump();

    expect(find.text('No sleep data for the last 7 days'), findsOneWidget);
  });

  testWidgets('shows chart with data when logs provided', (tester) async {
    final logs = [
      _log('s1', quality: 3, daysAgo: 6),
      _log('s2', quality: 4, daysAgo: 5),
      _log('s3', quality: 5, daysAgo: 4),
    ];
    await tester.pumpWidget(_buildChart(logs));
    await tester.pumpAndSettle();

    expect(find.text('Sleep Quality'), findsOneWidget);
    // Average should show
    expect(find.textContaining('Avg quality:'), findsOneWidget);
  });

  testWidgets('shows 7 days and 30 days toggle buttons', (tester) async {
    await tester.pumpWidget(_buildChart([]));
    await tester.pump();

    expect(find.text('7 days'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
  });

  testWidgets('toggling to 30 days shows 30-day empty state', (tester) async {
    await tester.pumpWidget(_buildChart([]));
    await tester.pump();

    await tester.tap(find.text('30 days'));
    await tester.pump();

    expect(find.text('No sleep data for the last 30 days'), findsOneWidget);
  });

  testWidgets('shows average quality label when logs present', (tester) async {
    final logs = [
      _log('s1', quality: 4, daysAgo: 2),
      _log('s2', quality: 2, daysAgo: 1),
    ];
    await tester.pumpWidget(_buildChart(logs));
    await tester.pumpAndSettle();

    // Average of 4 and 2 is 3.0
    expect(find.textContaining('3.0'), findsOneWidget);
  });
}
