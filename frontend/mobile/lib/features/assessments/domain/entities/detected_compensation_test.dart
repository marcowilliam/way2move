import 'package:flutter_test/flutter_test.dart';

import 'assessment.dart';
import 'detected_compensation.dart';

void main() {
  group('CompensationSeverity', () {
    test('fromFrameRatio returns mild when below 30%', () {
      expect(CompensationSeverity.fromFrameRatio(0.0), CompensationSeverity.mild);
      expect(CompensationSeverity.fromFrameRatio(0.10), CompensationSeverity.mild);
      expect(CompensationSeverity.fromFrameRatio(0.299), CompensationSeverity.mild);
    });

    test('fromFrameRatio returns moderate at exactly 30%', () {
      expect(CompensationSeverity.fromFrameRatio(0.30), CompensationSeverity.moderate);
    });

    test('fromFrameRatio returns moderate between 30% and 60%', () {
      expect(CompensationSeverity.fromFrameRatio(0.45), CompensationSeverity.moderate);
      expect(CompensationSeverity.fromFrameRatio(0.599), CompensationSeverity.moderate);
    });

    test('fromFrameRatio returns significant at exactly 60%', () {
      expect(CompensationSeverity.fromFrameRatio(0.60), CompensationSeverity.significant);
    });

    test('fromFrameRatio returns significant above 60%', () {
      expect(CompensationSeverity.fromFrameRatio(0.80), CompensationSeverity.significant);
      expect(CompensationSeverity.fromFrameRatio(1.0), CompensationSeverity.significant);
    });

    test('severity ordering: mild < moderate < significant', () {
      expect(
        CompensationSeverity.mild.index <
            CompensationSeverity.moderate.index &&
            CompensationSeverity.moderate.index <
                CompensationSeverity.significant.index,
        isTrue,
      );
    });
  });

  group('DetectedCompensation', () {
    const pattern = CompensationPattern.kneeValgus;

    test('frameRatio is affectedFrameCount / totalFrameCount', () {
      const d = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 6,
        totalFrameCount: 20,
      );
      expect(d.frameRatio, closeTo(0.3, 0.001));
    });

    test('frameRatio is 0 when totalFrameCount is 0', () {
      const d = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 0,
        totalFrameCount: 0,
      );
      expect(d.frameRatio, 0.0);
    });

    test('severity derives from frameRatio', () {
      const mild = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 5,
        totalFrameCount: 100,
      );
      expect(mild.severity, CompensationSeverity.mild);

      const moderate = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 40,
        totalFrameCount: 100,
      );
      expect(moderate.severity, CompensationSeverity.moderate);

      const significant = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 70,
        totalFrameCount: 100,
      );
      expect(significant.severity, CompensationSeverity.significant);
    });

    test('two DetectedCompensations are equal when pattern matches', () {
      const a = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 10,
        totalFrameCount: 50,
      );
      const b = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 20,
        totalFrameCount: 50,
      );
      expect(a, equals(b));
    });

    test('copyWith updates only specified fields', () {
      const original = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 5,
        totalFrameCount: 20,
      );
      final updated = original.copyWith(affectedFrameCount: 15);
      expect(updated.pattern, pattern);
      expect(updated.affectedFrameCount, 15);
      expect(updated.totalFrameCount, 20);
    });
  });
}
