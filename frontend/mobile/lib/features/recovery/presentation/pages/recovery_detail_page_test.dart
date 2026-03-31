import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/recovery/domain/entities/recovery_score.dart';
import 'package:way2move/features/recovery/domain/repositories/recovery_score_repository.dart';
import 'package:way2move/features/recovery/presentation/pages/recovery_detail_page.dart';
import 'package:way2move/features/recovery/presentation/providers/recovery_providers.dart';

class MockRecoveryScoreRepository extends Mock
    implements RecoveryScoreRepository {}

RecoveryScore _makeScore(double score) => RecoveryScore(
      id: 'rs1',
      userId: 'u1',
      date: DateTime.now(),
      score: score,
      components: const RecoveryScoreComponents(
        sleepComponent: 80,
        trainingLoadComponent: 60,
        weeklyPulseComponent: 70,
        gutFeelingComponent: 90,
      ),
      recommendation: 'Train as planned.',
    );

void main() {
  late MockRecoveryScoreRepository mockRepo;

  setUp(() {
    mockRepo = MockRecoveryScoreRepository();
  });

  Widget buildPage() => ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          recoveryScoreRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: RecoveryDetailPage(),
        ),
      );

  group('RecoveryDetailPage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final completer = Completer<Either<AppFailure, RecoveryScore?>>();
      when(() => mockRepo.getToday(any())).thenAnswer((_) => completer.future);
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildPage());
      // First pump before async resolves → loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Complete to avoid pending timer warnings
      completer.complete(const Right(null));
      await tester.pumpAndSettle();
    });

    testWidgets('shows no-data message when score is null', (tester) async {
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('No recovery data'), findsOneWidget);
    });

    testWidgets('shows score breakdown components', (tester) async {
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) async => Right(_makeScore(80)));
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Score Breakdown'), findsOneWidget);
      expect(find.text('Sleep Quality'), findsOneWidget);
      expect(find.text('Training Load'), findsOneWidget);
      expect(find.text('Weekly Pulse'), findsOneWidget);
      expect(find.text('Gut Feeling'), findsOneWidget);
    });

    testWidgets('shows 7-day trend section', (tester) async {
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) async => Right(_makeScore(80)));
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('7-Day Trend'), findsOneWidget);
    });

    testWidgets('shows recommendation card', (tester) async {
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) async => Right(_makeScore(80)));
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Recommendation headline for green zone
      expect(find.textContaining('well-recovered'), findsOneWidget);
    });
  });
}
