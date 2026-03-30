import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/journal/domain/services/entity_extraction_service.dart';
import 'package:way2move/features/journal/presentation/pages/review_auto_created_page.dart';

const testSession = ExtractedSession(
  activityType: 'running',
  durationMinutes: 30,
  bodyArea: 'hips',
  rawText: 'I ran for 30 minutes.',
);

const testMeal = ExtractedMeal(
  description: 'Chicken and rice for lunch',
  guessedMealType: MealType.lunch,
  stomachFeeling: 3,
  rawText: 'Ate chicken and rice for lunch.',
);

const testBodyMention = ExtractedBodyMention(
  bodyRegion: 'knee',
  sentiment: 'negative',
  rawText: 'My knee feels sore.',
);

void main() {
  Widget buildPage({
    List<ExtractedSession>? sessions,
    List<ExtractedMeal>? meals,
    List<ExtractedBodyMention>? bodyMentions,
  }) {
    return MaterialApp(
      home: ReviewAutoCreatedPage(
        journalId: 'j1',
        sessions: sessions ?? [],
        meals: meals ?? [],
        bodyMentions: bodyMentions ?? [],
      ),
    );
  }

  group('ReviewAutoCreatedPage', () {
    testWidgets('renders page key', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.reviewAutoCreatedPage), findsOneWidget);
    });

    testWidgets('renders Training Activities section when sessions present',
        (tester) async {
      await tester.pumpWidget(buildPage(sessions: [testSession]));
      await tester.pumpAndSettle();

      expect(find.text('Training Activities'), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
      expect(find.text('Duration: 30 min'), findsOneWidget);
    });

    testWidgets('renders Meals section when meals present', (tester) async {
      await tester.pumpWidget(buildPage(meals: [testMeal]));
      await tester.pumpAndSettle();

      expect(find.text('Meals'), findsOneWidget);
    });

    testWidgets('renders Body Awareness section when mentions present',
        (tester) async {
      await tester.pumpWidget(buildPage(bodyMentions: [testBodyMention]));
      await tester.pumpAndSettle();

      expect(find.text('Body Awareness'), findsOneWidget);
      expect(find.textContaining('knee'), findsOneWidget);
    });

    testWidgets('skip button is present', (tester) async {
      await tester.pumpWidget(buildPage(sessions: [testSession]));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.journalSkipButton), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('save & create button is present and enabled when items exist',
        (tester) async {
      await tester
          .pumpWidget(buildPage(sessions: [testSession], meals: [testMeal]));
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(AppKeys.journalSaveCreateButton);
      expect(saveBtn, findsOneWidget);

      final button = tester.widget<FilledButton>(saveBtn);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('save & create button is disabled when no items',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(AppKeys.journalSaveCreateButton);
      final button = tester.widget<FilledButton>(saveBtn);
      expect(button.onPressed, isNull);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('We found these from your journal'),
        findsOneWidget,
      );
    });
  });
}
