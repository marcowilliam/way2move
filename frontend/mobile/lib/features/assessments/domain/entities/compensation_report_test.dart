import 'package:flutter_test/flutter_test.dart';

import 'assessment.dart';
import 'compensation_report.dart';
import 'detected_compensation.dart';

void main() {
  final generated = DateTime(2026, 4, 1);

  group('CompensationReport', () {
    test('stores detections and metadata', () {
      final report = CompensationReport(
        assessmentId: 'assess1',
        userId: 'user1',
        detections: const [
          DetectedCompensation(
            pattern: CompensationPattern.kneeValgus,
            affectedFrameCount: 10,
            totalFrameCount: 20,
          ),
        ],
        generatedAt: generated,
      );

      expect(report.assessmentId, 'assess1');
      expect(report.userId, 'user1');
      expect(report.detections.length, 1);
      expect(report.generatedAt, generated);
    });

    test('isEmpty is true when detections list is empty', () {
      final report = CompensationReport(
        assessmentId: 'a',
        userId: 'u',
        detections: const [],
        generatedAt: generated,
      );
      expect(report.isEmpty, isTrue);
    });

    test('isEmpty is false when detections list is not empty', () {
      final report = CompensationReport(
        assessmentId: 'a',
        userId: 'u',
        detections: const [
          DetectedCompensation(
            pattern: CompensationPattern.roundedShoulders,
            affectedFrameCount: 5,
            totalFrameCount: 10,
          ),
        ],
        generatedAt: generated,
      );
      expect(report.isEmpty, isFalse);
    });

    test('detectionFor returns the matching DetectedCompensation', () {
      const detection = DetectedCompensation(
        pattern: CompensationPattern.kneeValgus,
        affectedFrameCount: 8,
        totalFrameCount: 20,
      );
      final report = CompensationReport(
        assessmentId: 'a',
        userId: 'u',
        detections: const [detection],
        generatedAt: generated,
      );
      expect(
        report.detectionFor(CompensationPattern.kneeValgus),
        detection,
      );
    });

    test('detectionFor returns null when pattern not present', () {
      final report = CompensationReport(
        assessmentId: 'a',
        userId: 'u',
        detections: const [],
        generatedAt: generated,
      );
      expect(
        report.detectionFor(CompensationPattern.kneeValgus),
        isNull,
      );
    });

    test('sortedByPriority orders significant first, then moderate, then mild',
        () {
      final report = CompensationReport(
        assessmentId: 'a',
        userId: 'u',
        detections: const [
          DetectedCompensation(
            pattern: CompensationPattern.roundedShoulders,
            affectedFrameCount: 5,
            totalFrameCount: 100, // mild
          ),
          DetectedCompensation(
            pattern: CompensationPattern.kneeValgus,
            affectedFrameCount: 80,
            totalFrameCount: 100, // significant
          ),
          DetectedCompensation(
            pattern: CompensationPattern.weakGluteMed,
            affectedFrameCount: 40,
            totalFrameCount: 100, // moderate
          ),
        ],
        generatedAt: generated,
      );

      final sorted = report.sortedByPriority;
      expect(sorted[0].severity, CompensationSeverity.significant);
      expect(sorted[1].severity, CompensationSeverity.moderate);
      expect(sorted[2].severity, CompensationSeverity.mild);
    });
  });

  group('CompensationReport.merge', () {
    test('includes video detections as-is when questionnaire is empty', () {
      const videoDetections = [
        DetectedCompensation(
          pattern: CompensationPattern.kneeValgus,
          affectedFrameCount: 10,
          totalFrameCount: 20,
        ),
      ];
      final report = CompensationReport.merge(
        assessmentId: 'a',
        userId: 'u',
        questionnairePatterns: const [],
        videoDetections: videoDetections,
        generatedAt: generated,
      );

      expect(report.detections.length, 1);
      expect(report.detections.first.pattern, CompensationPattern.kneeValgus);
      expect(report.detections.first.affectedFrameCount, 10);
    });

    test(
        'questionnaire-only patterns are added as mild with zero frame counts',
        () {
      final report = CompensationReport.merge(
        assessmentId: 'a',
        userId: 'u',
        questionnairePatterns: const [CompensationPattern.forwardHeadPosture],
        videoDetections: const [],
        generatedAt: generated,
      );

      expect(report.detections.length, 1);
      final d = report.detections.first;
      expect(d.pattern, CompensationPattern.forwardHeadPosture);
      expect(d.severity, CompensationSeverity.mild);
    });

    test('video detection takes precedence over questionnaire for same pattern',
        () {
      const videoDetection = DetectedCompensation(
        pattern: CompensationPattern.kneeValgus,
        affectedFrameCount: 70,
        totalFrameCount: 100, // significant
      );
      final report = CompensationReport.merge(
        assessmentId: 'a',
        userId: 'u',
        questionnairePatterns: const [CompensationPattern.kneeValgus],
        videoDetections: const [videoDetection],
        generatedAt: generated,
      );

      // Only one entry for kneeValgus, with video (significant) severity
      final matches = report.detections
          .where((d) => d.pattern == CompensationPattern.kneeValgus)
          .toList();
      expect(matches.length, 1);
      expect(matches.first.severity, CompensationSeverity.significant);
    });

    test('union includes patterns from both sources without duplicates', () {
      const videoDetection = DetectedCompensation(
        pattern: CompensationPattern.kneeValgus,
        affectedFrameCount: 40,
        totalFrameCount: 100,
      );
      final report = CompensationReport.merge(
        assessmentId: 'a',
        userId: 'u',
        questionnairePatterns: const [
          CompensationPattern.kneeValgus,
          CompensationPattern.roundedShoulders,
        ],
        videoDetections: const [videoDetection],
        generatedAt: generated,
      );

      final patterns = report.detections.map((d) => d.pattern).toSet();
      expect(patterns, containsAll([
        CompensationPattern.kneeValgus,
        CompensationPattern.roundedShoulders,
      ]));
      expect(report.detections.length, 2);
    });

    test('empty merge produces empty report', () {
      final report = CompensationReport.merge(
        assessmentId: 'a',
        userId: 'u',
        questionnairePatterns: const [],
        videoDetections: const [],
        generatedAt: generated,
      );
      expect(report.isEmpty, isTrue);
    });
  });
}
