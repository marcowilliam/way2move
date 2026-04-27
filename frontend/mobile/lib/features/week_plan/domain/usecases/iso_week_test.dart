import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/week_plan/domain/usecases/iso_week.dart';

void main() {
  group('mondayOf', () {
    test('returns the same date for a Monday', () {
      expect(mondayOf(DateTime(2026, 4, 27)), DateTime(2026, 4, 27));
    });

    test('returns the previous Monday for a Friday', () {
      expect(mondayOf(DateTime(2026, 5, 1)), DateTime(2026, 4, 27));
    });

    test('returns the previous Monday for a Sunday', () {
      expect(mondayOf(DateTime(2026, 5, 3)), DateTime(2026, 4, 27));
    });
  });

  group('isoYearWeekOf', () {
    test('formats April 27, 2026 (Mon) as 2026-W18', () {
      expect(isoYearWeekOf(DateTime(2026, 4, 27)), '2026-W18');
    });

    test('week 1 of 2026 covers Jan 4 (Sunday)', () {
      // Jan 4 2026 is a Sunday — ISO week 01 of 2026 starts Mon Dec 29 2025
      // and ends Sun Jan 4 2026, so Jan 4 is W01.
      expect(isoYearWeekOf(DateTime(2026, 1, 4)), '2026-W01');
    });

    test('Jan 1 2026 (Thu) is W01', () {
      expect(isoYearWeekOf(DateTime(2026, 1, 1)), '2026-W01');
    });

    test('zero-pads single-digit week numbers', () {
      expect(isoYearWeekOf(DateTime(2026, 1, 12)).endsWith('W03'), true);
    });
  });

  group('nextMondayOf', () {
    test('returns Monday + 7 days', () {
      expect(
        nextMondayOf(DateTime(2026, 4, 27)),
        DateTime(2026, 5, 4),
      );
    });
  });
}
