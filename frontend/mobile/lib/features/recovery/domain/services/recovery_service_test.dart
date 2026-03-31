import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/recovery/domain/entities/recovery_score.dart';
import 'package:way2move/features/recovery/domain/services/recovery_service.dart';
import 'package:way2move/features/sleep/domain/entities/sleep_log.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/nutrition/domain/entities/meal.dart';

void main() {
  final now = DateTime.now();

  // ── Helpers ────────────────────────────────────────────────────────────────

  SleepLog makeSleep({required int quality}) => SleepLog(
        id: 'sl-$quality',
        userId: 'u1',
        bedTime: now.subtract(const Duration(hours: 8)),
        wakeTime: now,
        quality: quality,
        date: now,
      );

  Session makeSession({
    required DateTime date,
    SessionStatus status = SessionStatus.completed,
  }) =>
      Session(
        id: 'sess-${date.millisecondsSinceEpoch}',
        userId: 'u1',
        date: date,
        status: status,
        exerciseBlocks: const [],
      );

  WeeklyPulse makePulse({
    required int energy,
    required int soreness,
    required int motivation,
    required int sleep,
  }) =>
      WeeklyPulse(
        id: 'wp',
        userId: 'u1',
        date: now,
        energyScore: energy,
        sorenessScore: soreness,
        motivationScore: motivation,
        sleepQualityScore: sleep,
      );

  Meal makeMeal({required int stomach}) => Meal(
        id: 'm-$stomach',
        userId: 'u1',
        date: now,
        mealType: MealType.lunch,
        description: 'meal',
        stomachFeeling: stomach,
      );

  // ── Sleep component ────────────────────────────────────────────────────────

  group('RecoveryService._sleepComponent', () {
    test('no sleep data returns neutral 50', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.sleepComponent, 50.0);
    });

    test('quality 1 maps to 0', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [makeSleep(quality: 1)],
        recentSessions: [],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.sleepComponent, 0.0);
    });

    test('quality 5 maps to 100', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [makeSleep(quality: 5)],
        recentSessions: [],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.sleepComponent, 100.0);
    });

    test('quality 3 maps to 50', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [makeSleep(quality: 3)],
        recentSessions: [],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.sleepComponent, 50.0);
    });

    test('averages multiple sleep logs', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [makeSleep(quality: 1), makeSleep(quality: 5)],
        recentSessions: [],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.sleepComponent, 50.0);
    });
  });

  // ── Training load component ────────────────────────────────────────────────

  group('RecoveryService._trainingLoadComponent', () {
    test('no sessions returns 75 (well-rested)', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.trainingLoadComponent, 75.0);
    });

    test('no load recently and previously returns 75', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [
          makeSession(
            date: now.subtract(const Duration(days: 10)),
          )
        ],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.trainingLoadComponent, 75.0);
    });

    test('higher recent load than baseline lowers score', () {
      // Heavy last 3 days, nothing in previous 4
      final c1 = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [
          makeSession(date: now.subtract(const Duration(days: 1))),
          makeSession(date: now.subtract(const Duration(days: 2))),
          makeSession(date: now.subtract(const Duration(days: 3))),
        ],
        weeklyPulses: [],
        meals: [],
      );

      // Light last 3 days, more in previous 4
      final c2 = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [
          makeSession(date: now.subtract(const Duration(days: 4))),
          makeSession(date: now.subtract(const Duration(days: 5))),
          makeSession(date: now.subtract(const Duration(days: 6))),
          makeSession(date: now.subtract(const Duration(days: 7))),
        ],
        weeklyPulses: [],
        meals: [],
      );

      expect(c2.trainingLoadComponent, greaterThan(c1.trainingLoadComponent));
    });

    test('planned sessions are not counted', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [
          makeSession(
            date: now.subtract(const Duration(days: 1)),
            status: SessionStatus.planned,
          ),
        ],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.trainingLoadComponent, 75.0);
    });
  });

  // ── Weekly pulse component ─────────────────────────────────────────────────

  group('RecoveryService._weeklyPulseComponent', () {
    test('no pulses returns neutral 50', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.weeklyPulseComponent, 50.0);
    });

    test('all scores at max (5) maps to 100', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [
          makePulse(energy: 5, soreness: 5, motivation: 5, sleep: 5)
        ],
        meals: [],
      );
      expect(c.weeklyPulseComponent, 100.0);
    });

    test('all scores at min (1) maps to 0', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [
          makePulse(energy: 1, soreness: 1, motivation: 1, sleep: 1)
        ],
        meals: [],
      );
      expect(c.weeklyPulseComponent, 0.0);
    });

    test('mid scores map to 50', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [
          makePulse(energy: 3, soreness: 3, motivation: 3, sleep: 3)
        ],
        meals: [],
      );
      expect(c.weeklyPulseComponent, 50.0);
    });
  });

  // ── Gut feeling component ──────────────────────────────────────────────────

  group('RecoveryService._gutFeelingComponent', () {
    test('no meals returns neutral 50', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [],
        meals: [],
      );
      expect(c.gutFeelingComponent, 50.0);
    });

    test('stomach 1 maps to 0', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [],
        meals: [makeMeal(stomach: 1)],
      );
      expect(c.gutFeelingComponent, 0.0);
    });

    test('stomach 5 maps to 100', () {
      final c = RecoveryService.calculateComponents(
        sleepLogs: [],
        recentSessions: [],
        weeklyPulses: [],
        meals: [makeMeal(stomach: 5)],
      );
      expect(c.gutFeelingComponent, 100.0);
    });
  });

  // ── Weighted sum ───────────────────────────────────────────────────────────

  group('RecoveryService.calculateScore', () {
    test('all zeros produces 0', () {
      const components = RecoveryScoreComponents(
        sleepComponent: 0,
        trainingLoadComponent: 0,
        weeklyPulseComponent: 0,
        gutFeelingComponent: 0,
      );
      expect(RecoveryService.calculateScore(components), 0.0);
    });

    test('all 100 produces 100', () {
      const components = RecoveryScoreComponents(
        sleepComponent: 100,
        trainingLoadComponent: 100,
        weeklyPulseComponent: 100,
        gutFeelingComponent: 100,
      );
      expect(RecoveryService.calculateScore(components), 100.0);
    });

    test('weights are correctly applied (30/40/20/10)', () {
      const components = RecoveryScoreComponents(
        sleepComponent: 100, // 30
        trainingLoadComponent: 0,
        weeklyPulseComponent: 0,
        gutFeelingComponent: 0,
      );
      expect(RecoveryService.calculateScore(components), closeTo(30.0, 0.001));
    });

    test('training load is the heaviest weight (40%)', () {
      const components = RecoveryScoreComponents(
        sleepComponent: 0,
        trainingLoadComponent: 100, // 40
        weeklyPulseComponent: 0,
        gutFeelingComponent: 0,
      );
      expect(RecoveryService.calculateScore(components), closeTo(40.0, 0.001));
    });

    test('score is clamped to 0–100', () {
      const components = RecoveryScoreComponents(
        sleepComponent: 200,
        trainingLoadComponent: 200,
        weeklyPulseComponent: 200,
        gutFeelingComponent: 200,
      );
      expect(RecoveryService.calculateScore(components), 100.0);
    });
  });

  // ── recommendationForScore ─────────────────────────────────────────────────

  group('RecoveryService.recommendationForScore', () {
    test('75 returns green recommendation', () {
      final r = RecoveryService.recommendationForScore(75);
      expect(r, contains('well-recovered'));
    });

    test('74 returns yellow recommendation', () {
      final r = RecoveryService.recommendationForScore(74);
      expect(r, contains('Mild fatigue'));
    });

    test('50 returns yellow recommendation', () {
      final r = RecoveryService.recommendationForScore(50);
      expect(r, contains('Mild fatigue'));
    });

    test('49 returns red recommendation', () {
      final r = RecoveryService.recommendationForScore(49);
      expect(r, contains('High fatigue'));
    });

    test('0 returns red recommendation', () {
      final r = RecoveryService.recommendationForScore(0);
      expect(r, contains('High fatigue'));
    });
  });
}
