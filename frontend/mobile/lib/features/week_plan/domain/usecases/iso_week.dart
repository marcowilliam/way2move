/// Pure helpers for ISO year-week math. Kept in domain layer so repos and
/// use cases share the same definition without the data layer reinventing
/// it. ISO 8601 weeks: Monday is day 1, Sunday is day 7; week 01 contains
/// the first Thursday of the year.
library;

/// Returns the ISO weekday (1=Mon … 7=Sun).
int isoWeekday(DateTime d) => d.weekday; // Dart's DateTime.weekday is ISO.

/// Returns the Monday at the start of `d`'s ISO week, normalized to local
/// midnight.
DateTime mondayOf(DateTime d) {
  final daysSinceMonday = isoWeekday(d) - 1;
  final monday = DateTime(d.year, d.month, d.day)
      .subtract(Duration(days: daysSinceMonday));
  return monday;
}

/// Returns next Monday (exclusive end of `d`'s ISO week).
DateTime nextMondayOf(DateTime d) => mondayOf(d).add(const Duration(days: 7));

/// Formats `d`'s ISO week as "YYYY-Www" — e.g. `2026-W18`.
///
/// Uses UTC-normalized dates internally so the day count isn't off by one
/// across DST transitions (where `Duration.inDays` truncates 24h-1h to 0
/// for that day).
String isoYearWeekOf(DateTime d) {
  // Thursday of the ISO week defines the year.
  final thursday = mondayOf(d).add(const Duration(days: 3));
  final year = thursday.year;

  // First ISO week contains Jan 4.
  final jan4 = DateTime(year, 1, 4);
  final firstMondayLocal = mondayOf(jan4);
  final mondayLocal = mondayOf(d);

  final firstMondayUtc = DateTime.utc(
    firstMondayLocal.year,
    firstMondayLocal.month,
    firstMondayLocal.day,
  );
  final mondayUtc = DateTime.utc(
    mondayLocal.year,
    mondayLocal.month,
    mondayLocal.day,
  );
  final weekNumber = (mondayUtc.difference(firstMondayUtc).inDays ~/ 7) + 1;

  return '$year-W${weekNumber.toString().padLeft(2, '0')}';
}
