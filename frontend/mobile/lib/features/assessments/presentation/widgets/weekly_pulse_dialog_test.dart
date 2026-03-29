import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';
import 'package:way2move/features/assessments/data/repositories/assessment_repository_impl.dart';
import 'package:way2move/features/assessments/presentation/widgets/weekly_pulse_dialog.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

const _kUserId = 'test_user';

void main() {
  late MockAssessmentRepository mockRepo;

  setUp(() {
    mockRepo = MockAssessmentRepository();
    registerFallbackValue(
      WeeklyPulse(
        id: '',
        userId: _kUserId,
        date: DateTime.utc(2026, 3, 29),
        energyScore: 3,
        sorenessScore: 3,
        motivationScore: 3,
        sleepQualityScore: 3,
      ),
    );
  });

  Widget buildDialog() {
    return ProviderScope(
      overrides: [
        assessmentRepositoryProvider.overrideWithValue(mockRepo),
        currentUserIdProvider.overrideWith((ref) => _kUserId),
      ],
      child: const MaterialApp(
        home: Scaffold(body: WeeklyPulseDialog()),
      ),
    );
  }

  group('WeeklyPulseDialog', () {
    testWidgets('renders with dialog key and all four slider labels',
        (tester) async {
      await tester.pumpWidget(buildDialog());

      expect(find.byKey(AppKeys.weeklyPulseDialog), findsOneWidget);
      expect(find.text('Weekly Pulse'), findsOneWidget);
      expect(find.text('Energy'), findsOneWidget);
      expect(find.text('Soreness'), findsOneWidget);
      expect(find.text('Motivation'), findsOneWidget);
      expect(find.text('Sleep Quality'), findsOneWidget);
    });

    testWidgets('shows Save Pulse button', (tester) async {
      await tester.pumpWidget(buildDialog());
      expect(find.text('Save Pulse'), findsOneWidget);
    });

    testWidgets('tapping Save Pulse calls logWeeklyPulse', (tester) async {
      // Use a taller surface so the button is on screen
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockRepo.logWeeklyPulse(any())).thenAnswer(
        (_) async => Right(
          WeeklyPulse(
            id: 'p1',
            userId: _kUserId,
            date: DateTime.utc(2026, 3, 29),
            energyScore: 3,
            sorenessScore: 3,
            motivationScore: 3,
            sleepQualityScore: 3,
          ),
        ),
      );

      await tester.pumpWidget(buildDialog());

      await tester.tap(find.text('Save Pulse'));
      // Pump microtasks so the async log() completes and verify passes
      await tester.pump();
      await tester.pump();

      verify(() => mockRepo.logWeeklyPulse(any())).called(1);

      // Advance past the 800ms "saved" display delay to clear pending timers
      await tester.pump(const Duration(milliseconds: 900));
    });
  });
}
