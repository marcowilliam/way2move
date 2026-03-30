import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/journal/data/repositories/journal_repository_impl.dart';
import 'package:way2move/features/journal/domain/entities/journal_entry.dart';
import 'package:way2move/features/journal/domain/repositories/journal_repository.dart';
import 'package:way2move/features/journal/presentation/pages/journal_history_page.dart';

class MockJournalRepository extends Mock implements JournalRepository {}

JournalEntry _entry(String id, JournalType type, String content) =>
    JournalEntry(
      id: id,
      userId: 'u1',
      date: DateTime(2024, 3, 1, 8),
      type: type,
      content: content,
      mood: 4,
    );

void main() {
  late MockJournalRepository mockRepo;

  setUp(() {
    mockRepo = MockJournalRepository();
  });

  Widget buildPage() {
    return ProviderScope(
      overrides: [
        journalRepositoryProvider.overrideWithValue(mockRepo),
        currentUserIdProvider.overrideWithValue('u1'),
      ],
      child: const MaterialApp(home: JournalHistoryPage()),
    );
  }

  group('JournalHistoryPage', () {
    testWidgets('shows empty state when no entries', (tester) async {
      when(() => mockRepo.getHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.journalHistoryPage), findsOneWidget);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
      expect(
        find.textContaining('No journal entries yet'),
        findsOneWidget,
      );
    });

    testWidgets('renders journal entries', (tester) async {
      final entries = [
        _entry('j1', JournalType.morningCheckIn, 'Slept great!'),
        _entry('j2', JournalType.eveningReflection, 'Good day overall.'),
      ];
      when(() => mockRepo.getHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(entries));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // 'Morning' appears in the filter chip AND in the type badge
      expect(find.text('Morning'), findsWidgets);
      expect(find.text('Evening'), findsWidgets);
      // Entry content
      expect(find.text('Slept great!'), findsOneWidget);
    });

    testWidgets('renders type badge for each entry', (tester) async {
      final entries = [
        _entry('j1', JournalType.postSession, 'Great session.'),
      ];
      when(() => mockRepo.getHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(entries));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // 'Post-Session' appears in the filter chip AND in the card type badge
      expect(find.text('Post-Session'), findsWidgets);
    });

    testWidgets('renders filter chips', (tester) async {
      when(() => mockRepo.getHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Morning'), findsWidgets);
    });

    testWidgets('renders mood emoji when mood is set', (tester) async {
      final entries = [
        _entry('j1', JournalType.general, 'Test'),
      ];
      when(() => mockRepo.getHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(entries));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // mood=4 → '😊'
      expect(find.text('😊'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (tester) async {
      // Use a completer that we never complete — simulates loading state
      final completer = Completer<Right<AppFailure, List<JournalEntry>>>();
      when(() => mockRepo.getHistory(any(), limit: any(named: 'limit')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildPage());
      await tester.pump(); // one frame — loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid pending timer warnings
      completer.complete(const Right([]));
      await tester.pumpAndSettle();
    });
  });
}
