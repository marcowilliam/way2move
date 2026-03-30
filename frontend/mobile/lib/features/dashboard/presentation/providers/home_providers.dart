import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sessions/domain/entities/session.dart';
import '../../../sessions/presentation/providers/session_providers.dart';

/// Number of consecutive days with at least one completed session,
/// counting backwards from today (or yesterday if today isn't done yet).
final streakProvider = Provider<int>((ref) {
  final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
  if (sessions.isEmpty) return 0;

  final completedDays = sessions
      .where((s) => s.status == SessionStatus.completed)
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet();

  final today = DateTime.now();
  var cursor = DateTime(today.year, today.month, today.day);

  // If nothing completed today, start counting from yesterday
  if (!completedDays.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  int streak = 0;
  while (completedDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
});

/// True if the user had NO completed session yesterday.
final missedYesterdayProvider = Provider<bool>((ref) {
  final sessions = ref.watch(sessionHistoryProvider).valueOrNull;
  // While loading, don't show the missed banner
  if (sessions == null) return false;

  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yd = DateTime(yesterday.year, yesterday.month, yesterday.day);
  final completedYesterday = sessions.any((s) =>
      s.status == SessionStatus.completed &&
      DateTime(s.date.year, s.date.month, s.date.day) == yd);
  return !completedYesterday;
});

/// Set of weekday numbers (1=Mon … 7=Sun) that had a completed session
/// during the current calendar week (Mon–Sun).
final weeklyCompletedDaysProvider = Provider<Set<int>>((ref) {
  final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final weekStart =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  final weekEnd = weekStart.add(const Duration(days: 7));

  return sessions
      .where((s) =>
          s.status == SessionStatus.completed &&
          !s.date.isBefore(weekStart) &&
          s.date.isBefore(weekEnd))
      .map((s) => s.date.weekday)
      .toSet();
});

/// Total number of completed sessions all-time.
final totalCompletedSessionsProvider = Provider<int>((ref) {
  final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
  return sessions.where((s) => s.status == SessionStatus.completed).length;
});
