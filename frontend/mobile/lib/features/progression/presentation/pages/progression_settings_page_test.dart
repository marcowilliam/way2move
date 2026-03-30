import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/progression/domain/entities/progression_rule.dart';
import 'package:way2move/features/progression/presentation/pages/progression_settings_page.dart';
import 'package:way2move/features/progression/presentation/providers/progression_providers.dart';

class _FakeGlobalRuleNotifier extends GlobalProgressionRuleNotifier {
  @override
  Future<ProgressionRule> build() async => const ProgressionRule();

  @override
  Future<Either<AppFailure, ProgressionRule>> save(ProgressionRule rule) async {
    state = AsyncData(rule);
    return Right(rule);
  }
}

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        globalProgressionRuleNotifierProvider
            .overrideWith(() => _FakeGlobalRuleNotifier()),
      ],
      child: const MaterialApp(
        home: ProgressionSettingsPage(),
      ),
    );
  }

  testWidgets('renders with correct AppBar title', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Auto-Progression Settings'), findsOneWidget);
  });

  testWidgets('has progression settings page key', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.progressionSettingsPage), findsOneWidget);
  });

  testWidgets('renders sliders for all four thresholds', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsNWidgets(4));
  });

  testWidgets('renders Global Thresholds section header', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Global Thresholds'), findsOneWidget);
  });

  testWidgets('renders About Auto-Progression section header', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('About Auto-Progression'), findsOneWidget);
  });

  testWidgets('renders Save button', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.progressionSaveButton), findsOneWidget);
  });

  testWidgets('shows default completionThreshold value of 3', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows default sleepThreshold value of 3.5', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('3.5'), findsOneWidget);
  });

  testWidgets('tapping Save button shows saved snackbar', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.progressionSaveButton));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Settings saved'), findsOneWidget);
  });
}
