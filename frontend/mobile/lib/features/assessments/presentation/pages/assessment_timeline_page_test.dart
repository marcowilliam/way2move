import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/assessments/data/repositories/assessment_repository_impl.dart';
import 'package:way2move/features/assessments/data/repositories/re_assessment_schedule_repository_impl.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/entities/re_assessment_schedule.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';
import 'package:way2move/features/assessments/domain/repositories/re_assessment_schedule_repository.dart';
import 'package:way2move/features/assessments/presentation/pages/assessment_timeline_page.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

class MockReAssessmentScheduleRepository extends Mock
    implements ReAssessmentScheduleRepository {}

Assessment _makeAssessment({
  required String id,
  required DateTime date,
  double overallScore = 7.5,
}) {
  return Assessment(
    id: id,
    userId: 'user1',
    date: date,
    answers: const {},
    compensationResults: const [CompensationPattern.kneeValgus],
    movementScores: const [],
    overallScore: overallScore,
  );
}

Widget _buildPage({
  List<Assessment> history = const [],
  ReAssessmentSchedule? schedule,
  AssessmentRepository? assessmentRepo,
  ReAssessmentScheduleRepository? scheduleRepo,
}) {
  final mockAssessmentRepo = assessmentRepo ?? MockAssessmentRepository();
  final mockScheduleRepo = scheduleRepo ?? MockReAssessmentScheduleRepository();

  if (assessmentRepo == null) {
    when(() => (mockAssessmentRepo as MockAssessmentRepository)
        .getAssessmentHistory(any())).thenAnswer((_) async => Right(history));
    when(() => (mockAssessmentRepo as MockAssessmentRepository)
        .getLatestAssessment(any())).thenAnswer((_) async => const Right(null));
    when(() => (mockAssessmentRepo as MockAssessmentRepository)
            .getLatestWeeklyPulse(any()))
        .thenAnswer((_) async => const Right(null));
  }
  if (scheduleRepo == null) {
    when(() => (mockScheduleRepo as MockReAssessmentScheduleRepository)
        .getSchedule(any())).thenAnswer((_) async => Right(schedule));
  }

  return ProviderScope(
    overrides: [
      assessmentRepositoryProvider.overrideWithValue(mockAssessmentRepo),
      reAssessmentScheduleRepositoryProvider
          .overrideWithValue(mockScheduleRepo),
      currentUserIdProvider.overrideWithValue('user1'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/assessment/timeline',
        routes: [
          GoRoute(
            path: '/assessment/timeline',
            builder: (_, __) => const AssessmentTimelinePage(),
          ),
          GoRoute(
            path: '/assessment/history',
            builder: (_, __) => const Scaffold(body: Text('History')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('AssessmentTimelinePage', () {
    testWidgets('shows empty state when no assessments', (tester) async {
      await tester.pumpWidget(_buildPage(history: const []));
      await tester.pumpAndSettle();

      expect(find.text('No Assessments Yet'), findsOneWidget);
    });

    testWidgets('shows timeline items for each assessment', (tester) async {
      final history = [
        _makeAssessment(
            id: 'a1', date: DateTime(2026, 3, 30), overallScore: 8.0),
        _makeAssessment(
            id: 'a2', date: DateTime(2026, 2, 28), overallScore: 6.0),
      ];

      await tester.pumpWidget(_buildPage(history: history));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timelineItem_a1')), findsOneWidget);
      expect(find.byKey(const Key('timelineItem_a2')), findsOneWidget);
    });

    testWidgets('shows Latest badge on first item', (tester) async {
      final history = [
        _makeAssessment(id: 'a1', date: DateTime(2026, 3, 30)),
        _makeAssessment(id: 'a2', date: DateTime(2026, 2, 28)),
      ];

      await tester.pumpWidget(_buildPage(history: history));
      await tester.pumpAndSettle();

      expect(find.text('Latest'), findsOneWidget);
    });

    testWidgets('shows schedule settings button', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scheduleSettingsButton')), findsOneWidget);
    });

    testWidgets('tapping schedule settings shows interval picker',
        (tester) async {
      final schedule = ReAssessmentSchedule(
        id: 'user1',
        userId: 'user1',
        nextAssessmentDate: DateTime(2026, 4, 27),
        intervalWeeks: 4,
      );

      await tester.pumpWidget(_buildPage(schedule: schedule));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('scheduleSettingsButton')));
      await tester.pumpAndSettle();

      expect(find.text('Re-assessment Interval'), findsOneWidget);
      expect(find.byKey(const Key('intervalOption_4')), findsOneWidget);
      expect(find.byKey(const Key('intervalOption_6')), findsOneWidget);
      expect(find.byKey(const Key('intervalOption_8')), findsOneWidget);
      expect(find.byKey(const Key('intervalOption_12')), findsOneWidget);
    });

    testWidgets('shows up trend arrow when score improved', (tester) async {
      final history = [
        _makeAssessment(
            id: 'a1', date: DateTime(2026, 3, 30), overallScore: 8.5),
        _makeAssessment(
            id: 'a2', date: DateTime(2026, 2, 28), overallScore: 6.0),
      ];

      await tester.pumpWidget(_buildPage(history: history));
      await tester.pumpAndSettle();

      // The first (latest) item should show an up arrow
      expect(
        find.byIcon(Icons.arrow_upward_rounded),
        findsOneWidget,
      );
    });

    testWidgets('shows down trend arrow when score worsened', (tester) async {
      final history = [
        _makeAssessment(
            id: 'a1', date: DateTime(2026, 3, 30), overallScore: 5.0),
        _makeAssessment(
            id: 'a2', date: DateTime(2026, 2, 28), overallScore: 8.0),
      ];

      await tester.pumpWidget(_buildPage(history: history));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });
  });
}
