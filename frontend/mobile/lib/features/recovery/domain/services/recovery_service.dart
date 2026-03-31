import '../../../sleep/domain/entities/sleep_log.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../assessments/domain/entities/assessment.dart';
import '../../../nutrition/domain/entities/meal.dart';
import '../entities/recovery_score.dart';

/// Pure Dart service — no Flutter or Firebase imports.
/// Calculates recovery score components from raw data.
abstract class RecoveryService {
  /// Weights: sleep 30%, training load 40%, weekly pulse 20%, gut 10%.
  static RecoveryScoreComponents calculateComponents({
    required List<SleepLog> sleepLogs,
    required List<Session> recentSessions,
    required List<WeeklyPulse> weeklyPulses,
    required List<Meal> meals,
  }) {
    final sleep = _sleepComponent(sleepLogs);
    final load = _trainingLoadComponent(recentSessions);
    final pulse = _weeklyPulseComponent(weeklyPulses);
    final gut = _gutFeelingComponent(meals);
    return RecoveryScoreComponents(
      sleepComponent: sleep,
      trainingLoadComponent: load,
      weeklyPulseComponent: pulse,
      gutFeelingComponent: gut,
    );
  }

  static double calculateScore(RecoveryScoreComponents c) {
    final raw = c.sleepComponent * 0.30 +
        c.trainingLoadComponent * 0.40 +
        c.weeklyPulseComponent * 0.20 +
        c.gutFeelingComponent * 0.10;
    return raw.clamp(0.0, 100.0);
  }

  static String recommendationForScore(double score) {
    if (score >= 75) return "You're well-recovered. Train as planned.";
    if (score >= 50) {
      return 'Mild fatigue. Consider reducing volume by 20% or swapping to mobility work.';
    }
    return 'High fatigue. Take a rest day or do light active recovery only.';
  }

  // ── Component calculators ──────────────────────────────────────────────────

  /// Sleep quality: average of quality scores (1–5) mapped to 0–100.
  static double _sleepComponent(List<SleepLog> logs) {
    if (logs.isEmpty) return 50.0; // neutral default when no data
    final avg =
        logs.map((l) => l.quality).reduce((a, b) => a + b) / logs.length;
    return ((avg - 1) / 4.0 * 100.0).clamp(0.0, 100.0);
  }

  /// Training load trend: higher recovery when recent load is decreasing.
  ///
  /// Compares completed sessions in last 3 days vs the 7-day daily average.
  /// If load is decreasing (recent < average), score is higher.
  static double _trainingLoadComponent(List<Session> sessions) {
    if (sessions.isEmpty) return 75.0; // no training = well-rested

    final now = DateTime.now();
    final cutoff3 = now.subtract(const Duration(days: 3));
    final cutoff7 = now.subtract(const Duration(days: 7));

    final completed =
        sessions.where((s) => s.status == SessionStatus.completed).toList();

    final last3 = completed.where((s) => s.date.isAfter(cutoff3)).length;
    final last7 = completed
        .where((s) => s.date.isAfter(cutoff7) && !s.date.isAfter(cutoff3))
        .length;

    // Daily averages
    final dailyLast3 = last3 / 3.0;
    final dailyPrev4 = last7 / 4.0; // previous 4 days (day 4–7)

    // If no prior sessions, treat as no load
    if (dailyPrev4 == 0 && dailyLast3 == 0) return 75.0;
    if (dailyPrev4 == 0) {
      // Suddenly training after rest — moderate score
      return 50.0;
    }

    // ratio: recent load vs baseline. Lower ratio = more recovery = higher score.
    final ratio = dailyLast3 / dailyPrev4;
    // ratio 0 (no recent load) → score 100; ratio 1 (same load) → score 50; ratio ≥ 2 → score 0
    final score = (1.0 - (ratio / 2.0).clamp(0.0, 1.0)) * 100.0;
    return score.clamp(0.0, 100.0);
  }

  /// Weekly pulse composite: average of energy + (100-soreness%) + motivation + sleep.
  /// Each field is 1–5, mapped to 0–100.
  static double _weeklyPulseComponent(List<WeeklyPulse> pulses) {
    if (pulses.isEmpty) return 50.0;

    double total = 0;
    for (final p in pulses) {
      final energy = (p.energyScore - 1) / 4.0 * 100.0;
      // sorenessScore: 1=very sore (bad), 5=no soreness (good)
      final soreness = (p.sorenessScore - 1) / 4.0 * 100.0;
      final motivation = (p.motivationScore - 1) / 4.0 * 100.0;
      final sleep = (p.sleepQualityScore - 1) / 4.0 * 100.0;
      total += (energy + soreness + motivation + sleep) / 4.0;
    }
    return (total / pulses.length).clamp(0.0, 100.0);
  }

  /// Gut feeling: average stomach feeling (1–5) mapped to 0–100.
  static double _gutFeelingComponent(List<Meal> meals) {
    if (meals.isEmpty) return 50.0;
    final avg = meals.map((m) => m.stomachFeeling).reduce((a, b) => a + b) /
        meals.length;
    return ((avg - 1) / 4.0 * 100.0).clamp(0.0, 100.0);
  }
}
