import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../sessions/data/repositories/session_repository_impl.dart';
import '../../../sessions/domain/entities/session.dart';

enum CalendarMode { month, week }

/// Currently selected day on the calendar.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Currently active calendar display mode.
final calendarModeProvider = StateProvider<CalendarMode>((ref) {
  return CalendarMode.month;
});

/// All sessions for the given month (first day of month as key).
/// Fetches session history and filters to the requested month.
final sessionsForMonthProvider =
    StreamProvider.family<List<Session>, DateTime>((ref, month) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();

  final repo = ref.watch(sessionRepositoryProvider);
  final firstDay = DateTime(month.year, month.month, 1);
  final lastDay = DateTime(month.year, month.month + 1, 1);

  // Watch today's sessions as a reactivity hook, then fold history.
  // Sessions history is a one-shot future; wrap it as a stream.
  return Stream.fromFuture(
    repo.getSessionHistory(userId).then(
          (result) => result.fold(
            (_) => <Session>[],
            (all) => all
                .where(
                  (s) => !s.date.isBefore(firstDay) && s.date.isBefore(lastDay),
                )
                .toList(),
          ),
        ),
  );
});

/// Sessions for a specific day — derived from the month stream.
final sessionsForDayProvider =
    Provider.family<AsyncValue<List<Session>>, DateTime>((ref, day) {
  final normalised = DateTime(day.year, day.month, day.day);
  final monthStart = DateTime(day.year, day.month, 1);
  final monthAsync = ref.watch(sessionsForMonthProvider(monthStart));

  return monthAsync.whenData(
    (sessions) => sessions
        .where((s) =>
            s.date.year == normalised.year &&
            s.date.month == normalised.month &&
            s.date.day == normalised.day)
        .toList(),
  );
});
