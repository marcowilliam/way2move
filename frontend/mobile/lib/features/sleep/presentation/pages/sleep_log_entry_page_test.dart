import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/sleep/data/repositories/sleep_repository_impl.dart';
import 'package:way2move/features/sleep/domain/entities/sleep_log.dart';
import 'package:way2move/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:way2move/features/sleep/presentation/pages/sleep_log_entry_page.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';

class MockSleepRepository extends Mock implements SleepRepository {}

SleepLog _fakeSleepLog() => SleepLog(
      id: 'sl1',
      userId: 'u1',
      bedTime: DateTime(2024, 1, 1, 22, 0),
      wakeTime: DateTime(2024, 1, 2, 6, 0),
      quality: 4,
      date: DateTime(2024, 1, 2),
    );

Widget _buildPage(MockSleepRepository mockRepo) {
  return ProviderScope(
    overrides: [
      sleepRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('u1'),
    ],
    child: const MaterialApp(
      home: SleepLogEntryPage(),
    ),
  );
}

void main() {
  late MockSleepRepository mockRepo;

  setUp(() {
    mockRepo = MockSleepRepository();
  });

  setUpAll(() {
    registerFallbackValue(_fakeSleepLog());
  });

  testWidgets('renders sleep entry page with key', (tester) async {
    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pump();

    expect(find.byKey(AppKeys.sleepEntryWidget), findsOneWidget);
  });

  testWidgets('shows bed time and wake time pickers', (tester) async {
    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pump();

    expect(find.text('Bed time'), findsOneWidget);
    expect(find.text('Wake time'), findsOneWidget);
  });

  testWidgets('shows Log Sleep title', (tester) async {
    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pump();

    expect(find.text('Log Sleep'), findsOneWidget);
  });

  testWidgets('save button is disabled when no quality is selected',
      (tester) async {
    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Sleep Log'),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('save button becomes enabled after selecting quality',
      (tester) async {
    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pump();

    // Tap quality chip "4"
    await tester.tap(find.text('4'));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Sleep Log'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('shows quality labels 1 through 5', (tester) async {
    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pump();

    for (var i = 1; i <= 5; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
  });

  testWidgets('calls logSleep and shows success snackbar on save',
      (tester) async {
    final log = _fakeSleepLog();
    when(() => mockRepo.logSleep(any())).thenAnswer((_) async => Right(log));

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pump();

    // Select quality 4
    await tester.tap(find.text('4'));
    await tester.pump();

    // Ensure save button is visible
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Save Sleep Log'));
    await tester.pump();

    // Tap save
    await tester.tap(
      find.widgetWithText(FilledButton, 'Save Sleep Log'),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => mockRepo.logSleep(any())).called(1);
    expect(find.text('Sleep log saved!'), findsOneWidget);
  });

  testWidgets('shows error snackbar when save fails', (tester) async {
    when(() => mockRepo.logSleep(any())).thenAnswer(
      (_) async => const Left(ServerFailure()),
    );

    await tester.pumpWidget(_buildPage(mockRepo));
    await tester.pump();

    await tester.tap(find.text('3'));
    await tester.pump();

    // Ensure save button is visible
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Save Sleep Log'));
    await tester.pump();

    await tester.tap(
      find.widgetWithText(FilledButton, 'Save Sleep Log'),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Failed to save sleep log. Please try again.'),
      findsOneWidget,
    );
  });
}
