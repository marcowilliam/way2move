import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/journal/data/repositories/journal_repository_impl.dart';
import 'package:way2move/features/journal/domain/repositories/journal_repository.dart';
import 'package:way2move/features/journal/domain/services/entity_extraction_service.dart'
    as extraction;
import 'package:way2move/features/journal/presentation/pages/review_auto_created_page.dart';
import 'package:way2move/features/nutrition/data/repositories/meal_repository_impl.dart';
import 'package:way2move/features/nutrition/domain/entities/meal.dart';
import 'package:way2move/features/nutrition/domain/repositories/meal_repository.dart';
import 'package:way2move/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockMealRepository extends Mock implements MealRepository {}

class MockJournalRepository extends Mock implements JournalRepository {}

const _testSession = extraction.ExtractedSession(
  activityType: 'running',
  durationMinutes: 30,
  bodyArea: 'hips',
  rawText: 'I ran for 30 minutes.',
);

const _testMeal = extraction.ExtractedMeal(
  description: 'Chicken and rice for lunch',
  guessedMealType: extraction.MealType.lunch,
  stomachFeeling: 3,
  rawText: 'Ate chicken and rice for lunch.',
);

const _testBodyMention = extraction.ExtractedBodyMention(
  bodyRegion: 'knee',
  sentiment: 'negative',
  rawText: 'My knee feels sore.',
);

void main() {
  late MockSessionRepository sessionRepo;
  late MockMealRepository mealRepo;
  late MockJournalRepository journalRepo;

  setUp(() {
    sessionRepo = MockSessionRepository();
    mealRepo = MockMealRepository();
    journalRepo = MockJournalRepository();

    registerFallbackValue(
      Session(
        id: '',
        userId: '',
        date: DateTime(2020),
        status: SessionStatus.planned,
        exerciseBlocks: const [],
      ),
    );
    registerFallbackValue(
      Meal(
        id: '',
        userId: '',
        date: DateTime(2020),
        mealType: MealType.snack,
        description: '',
        stomachFeeling: 3,
      ),
    );
  });

  Widget buildPage({
    List<extraction.ExtractedSession>? sessions,
    List<extraction.ExtractedMeal>? meals,
    List<extraction.ExtractedBodyMention>? bodyMentions,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user1'),
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
        mealRepositoryProvider.overrideWithValue(mealRepo),
        journalRepositoryProvider.overrideWithValue(journalRepo),
      ],
      child: MaterialApp(
        home: ReviewAutoCreatedPage(
          journalId: 'j1',
          sessions: sessions ?? [],
          meals: meals ?? [],
          bodyMentions: bodyMentions ?? [],
        ),
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
      await tester.pumpWidget(buildPage(sessions: [_testSession]));
      await tester.pumpAndSettle();

      expect(find.text('Training Activities'), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
      expect(find.text('Duration: 30 min'), findsOneWidget);
    });

    testWidgets('renders Meals section when meals present', (tester) async {
      await tester.pumpWidget(buildPage(meals: [_testMeal]));
      await tester.pumpAndSettle();

      expect(find.text('Meals'), findsOneWidget);
    });

    testWidgets('renders Body Awareness section when mentions present',
        (tester) async {
      await tester.pumpWidget(buildPage(bodyMentions: [_testBodyMention]));
      await tester.pumpAndSettle();

      expect(find.text('Body Awareness'), findsOneWidget);
      expect(find.textContaining('knee'), findsOneWidget);
    });

    testWidgets('skip button is present', (tester) async {
      await tester.pumpWidget(buildPage(sessions: [_testSession]));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.journalSkipButton), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('save & create button is present and enabled when items exist',
        (tester) async {
      await tester
          .pumpWidget(buildPage(sessions: [_testSession], meals: [_testMeal]));
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

    testWidgets('save creates session and meal, updates journal',
        (tester) async {
      final createdSession = Session(
        id: 'sess1',
        userId: 'user1',
        date: DateTime(2020),
        status: SessionStatus.completed,
        exerciseBlocks: const [],
      );
      final createdMeal = Meal(
        id: 'meal1',
        userId: 'user1',
        date: DateTime(2020),
        mealType: MealType.lunch,
        description: 'Chicken and rice for lunch',
        stomachFeeling: 3,
        origin: 'voice',
      );

      when(() => sessionRepo.createSession(any()))
          .thenAnswer((_) async => Right(createdSession));
      when(() => mealRepo.createMeal(any()))
          .thenAnswer((_) async => Right(createdMeal));
      when(() => journalRepo.updateAutoCreatedEntities(any(), any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(buildPage(
        sessions: [_testSession],
        meals: [_testMeal],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.journalSaveCreateButton));
      await tester.pumpAndSettle();

      verify(() => sessionRepo.createSession(any())).called(1);
      verify(() => mealRepo.createMeal(any())).called(1);
      verify(() => journalRepo.updateAutoCreatedEntities(
            'j1',
            any(that: containsAll(['sess1', 'meal1'])),
          )).called(1);
    });
  });
}
