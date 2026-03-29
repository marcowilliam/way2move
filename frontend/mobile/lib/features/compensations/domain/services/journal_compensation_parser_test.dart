import 'package:flutter_test/flutter_test.dart';

import '../entities/compensation.dart';
import 'journal_compensation_parser.dart';

void main() {
  group('JournalCompensationParser.parse', () {
    test('detects lower back pain mention', () {
      const text = 'My lower back is really sore after sitting all day.';
      final result = JournalCompensationParser.parse(text);

      expect(result.hasNewMentions, true);
      expect(
        result.newMentions
            .any((m) => m.region == CompensationRegion.lumbarSpine),
        true,
      );
    });

    test('detects neck tightness as mobility deficit', () {
      const text = 'Neck feels tight this morning, limited range of motion.';
      final result = JournalCompensationParser.parse(text);

      expect(result.hasNewMentions, true);
      final mention = result.newMentions
          .firstWhere((m) => m.region == CompensationRegion.cervicalSpine);
      expect(mention.type, CompensationType.mobilityDeficit);
    });

    test('detects left knee mention', () {
      const text = 'Left knee aches after the run.';
      final result = JournalCompensationParser.parse(text);

      expect(
          result.newMentions
              .any((m) => m.region == CompensationRegion.leftKnee),
          true);
    });

    test('improvement signal marks region as improving, not new', () {
      const text = 'Lower back is much better, no pain anymore.';
      final result = JournalCompensationParser.parse(text);

      expect(result.hasImprovements, true);
      expect(
        result.improvingRegions.contains(CompensationRegion.lumbarSpine),
        true,
      );
      // Should NOT create a new mention for the same region
      expect(
        result.newMentions
            .any((m) => m.region == CompensationRegion.lumbarSpine),
        false,
      );
    });

    test('text with no body keywords returns empty result', () {
      const text = 'Had a great workout, feeling energised and motivated!';
      final result = JournalCompensationParser.parse(text);

      expect(result.hasNewMentions, false);
      expect(result.hasImprovements, false);
    });

    test('detects multiple regions in one journal entry', () {
      const text =
          'My neck is stiff and my lower back hurts. Left shoulder feels tight too.';
      final result = JournalCompensationParser.parse(text);

      final regions = result.newMentions.map((m) => m.region).toSet();
      expect(regions.contains(CompensationRegion.cervicalSpine), true);
      expect(regions.contains(CompensationRegion.lumbarSpine), true);
      expect(regions.contains(CompensationRegion.leftShoulder), true);
    });

    test('stability signal maps to stabilityDeficit type', () {
      const text = 'Core feels really weak and unstable during planks.';
      final result = JournalCompensationParser.parse(text);

      expect(result.hasNewMentions, true);
      final mention = result.newMentions
          .firstWhere((m) => m.region == CompensationRegion.core);
      expect(mention.type, CompensationType.stabilityDeficit);
    });

    test('returns unique mentions — same region not duplicated', () {
      const text = 'Hip pain, left hip sore, hip hurts.';
      final result = JournalCompensationParser.parse(text);

      final hipMentions = result.newMentions
          .where((m) => m.region == CompensationRegion.pelvis)
          .toList();
      // Should appear at most once
      expect(hipMentions.length, lessThanOrEqualTo(1));
    });

    test('case-insensitive matching', () {
      const text = 'NECK IS TIGHT AND SORE.';
      final result = JournalCompensationParser.parse(text);

      expect(
        result.newMentions
            .any((m) => m.region == CompensationRegion.cervicalSpine),
        true,
      );
    });
  });
}
