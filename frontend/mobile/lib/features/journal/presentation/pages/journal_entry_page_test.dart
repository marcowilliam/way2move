import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/journal/data/repositories/journal_repository_impl.dart';
import 'package:way2move/features/journal/domain/entities/journal_entry.dart';
import 'package:way2move/features/journal/domain/repositories/journal_repository.dart';
import 'package:way2move/features/journal/presentation/pages/journal_entry_page.dart';

class MockJournalRepository extends Mock implements JournalRepository {}

JournalEntry _stubEntry() => JournalEntry(
      id: 'j1',
      userId: 'u1',
      date: DateTime(2024, 1, 1),
      type: JournalType.general,
      content: 'Test',
    );

void main() {
  late MockJournalRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(_stubEntry());
  });

  setUp(() {
    mockRepo = MockJournalRepository();
    // Stub getHistory for notifier build
    when(() => mockRepo.getHistory(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right([]));
  });

  Widget buildPage({JournalType type = JournalType.general}) {
    return ProviderScope(
      overrides: [
        journalRepositoryProvider.overrideWithValue(mockRepo),
        currentUserIdProvider.overrideWithValue('u1'),
      ],
      child: MaterialApp(
        home: JournalEntryPage(type: type),
      ),
    );
  }

  group('JournalEntryPage', () {
    testWidgets('renders correct title for morningCheckIn', (tester) async {
      await tester.pumpWidget(buildPage(type: JournalType.morningCheckIn));
      await tester.pumpAndSettle();

      expect(find.text('Morning Check-In'), findsOneWidget);
    });

    testWidgets('renders correct title for postSession', (tester) async {
      await tester.pumpWidget(buildPage(type: JournalType.postSession));
      await tester.pumpAndSettle();

      expect(find.text('Post-Session Reflection'), findsOneWidget);
    });

    testWidgets('renders contextual prompt for postSession', (tester) async {
      await tester.pumpWidget(buildPage(type: JournalType.postSession));
      await tester.pumpAndSettle();

      expect(
        find.text('How did your session go? Any pain or tightness?'),
        findsOneWidget,
      );
    });

    testWidgets('renders content text field', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.journalContentField), findsOneWidget);
    });

    testWidgets('renders mood emoji chips', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('😔'), findsOneWidget);
      expect(find.text('🤩'), findsOneWidget);
    });

    testWidgets('shows snackbar when saving empty content', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.journalSaveButton).first);
      await tester.pumpAndSettle();

      expect(
        find.text('Please add some content first.'),
        findsOneWidget,
      );
    });

    testWidgets('calls repository create when content is provided and saved',
        (tester) async {
      when(() => mockRepo.create(any()))
          .thenAnswer((_) async => Right(_stubEntry()));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(AppKeys.journalContentField), 'Test content');
      await tester.tap(find.byKey(AppKeys.journalSaveButton).first);
      await tester.pumpAndSettle();

      verify(() => mockRepo.create(any())).called(1);
    });

    testWidgets('renders pain point chips', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Pain points are inside a scrollable ListView — scroll down to find them
      await tester.scrollUntilVisible(
        find.text('neck'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('neck'), findsOneWidget);
      expect(find.text('knees'), findsOneWidget);
    });

    testWidgets('renders evening reflection prompt', (tester) async {
      await tester.pumpWidget(buildPage(type: JournalType.eveningReflection));
      await tester.pumpAndSettle();

      expect(
        find.text('Summarize your day. What went well?'),
        findsOneWidget,
      );
    });
  });
}
