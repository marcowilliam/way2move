import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/recovery/domain/entities/recovery_score.dart';
import 'package:way2move/features/recovery/domain/repositories/recovery_score_repository.dart';
import 'package:way2move/features/recovery/presentation/providers/recovery_providers.dart';
import 'package:way2move/features/recovery/presentation/widgets/recovery_banner.dart';

class MockRecoveryScoreRepository extends Mock
    implements RecoveryScoreRepository {}

RecoveryScore _makeScore(double score) => RecoveryScore(
      id: 'rs1',
      userId: 'u1',
      date: DateTime.now(),
      score: score,
      components: const RecoveryScoreComponents(
        sleepComponent: 80,
        trainingLoadComponent: 70,
        weeklyPulseComponent: 60,
        gutFeelingComponent: 75,
      ),
      recommendation: 'Test recommendation',
    );

void main() {
  late MockRecoveryScoreRepository mockRepo;

  setUp(() {
    mockRepo = MockRecoveryScoreRepository();
  });

  Widget buildBanner() => ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          recoveryScoreRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RecoveryBanner()),
        ),
      );

  group('RecoveryBanner', () {
    testWidgets('shows skeleton while loading', (tester) async {
      // Completer never completes → stays loading
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) => Future.value(const Right(null)));

      await tester.pumpWidget(buildBanner());
      // First frame is loading state
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows no-data card when score is null', (tester) async {
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(buildBanner());
      await tester.pumpAndSettle();

      expect(find.text('Recovery Score'), findsOneWidget);
      expect(find.textContaining('No data yet'), findsOneWidget);
    });

    testWidgets('shows score number after data loads (green)', (tester) async {
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) async => Right(_makeScore(85)));

      await tester.pumpWidget(buildBanner());
      await tester.pumpAndSettle();

      expect(find.text('Recovery Score'), findsOneWidget);
      // Zone chip label
      expect(find.text('Green'), findsOneWidget);
    });

    testWidgets('shows yellow zone chip for score 60', (tester) async {
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) async => Right(_makeScore(60)));

      await tester.pumpWidget(buildBanner());
      await tester.pumpAndSettle();

      expect(find.text('Yellow'), findsOneWidget);
    });

    testWidgets('shows red zone chip for score 30', (tester) async {
      when(() => mockRepo.getToday(any()))
          .thenAnswer((_) async => Right(_makeScore(30)));

      await tester.pumpWidget(buildBanner());
      await tester.pumpAndSettle();

      expect(find.text('Red'), findsOneWidget);
    });
  });
}
