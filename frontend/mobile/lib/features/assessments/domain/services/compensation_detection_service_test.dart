import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/services/compensation_detection_service.dart';

void main() {
  group('CompensationDetectionService', () {
    group('detectCompensations', () {
      test('returns empty list when no risk factors', () {
        final result = CompensationDetectionService.detectCompensations({
          'occupation': 'active',
          'sittingHours': 'lt2',
          'neckPain': false,
          'lowerBackPain': false,
          'kneePain': false,
          'isRunner': false,
          'anklePain': false,
          'shoulderPainOverhead': false,
        });

        expect(result, isEmpty);
      });

      test(
          'detects forward head posture and rounded shoulders for desk worker with neck pain',
          () {
        final result = CompensationDetectionService.detectCompensations({
          'occupation': 'desk',
          'sittingHours': '2to4',
          'neckPain': true,
          'lowerBackPain': false,
          'kneePain': false,
          'isRunner': false,
          'anklePain': false,
          'shoulderPainOverhead': false,
        });

        expect(
            result,
            containsAll([
              CompensationPattern.forwardHeadPosture,
              CompensationPattern.roundedShoulders,
            ]));
      });

      test('detects anterior pelvic tilt and poor core for sitting >6h/day',
          () {
        final result = CompensationDetectionService.detectCompensations({
          'occupation': 'desk',
          'sittingHours': 'gt6',
          'neckPain': false,
          'lowerBackPain': false,
          'kneePain': false,
          'isRunner': false,
          'anklePain': false,
          'shoulderPainOverhead': false,
        });

        expect(
            result,
            containsAll([
              CompensationPattern.anteriorPelvicTilt,
              CompensationPattern.poorCoreStability,
            ]));
      });

      test('detects knee valgus and weak glute med for runner with knee pain',
          () {
        final result = CompensationDetectionService.detectCompensations({
          'occupation': 'active',
          'sittingHours': 'lt2',
          'neckPain': false,
          'lowerBackPain': false,
          'kneePain': true,
          'isRunner': true,
          'anklePain': false,
          'shoulderPainOverhead': false,
        });

        expect(
            result,
            containsAll([
              CompensationPattern.kneeValgus,
              CompensationPattern.weakGluteMed,
            ]));
      });

      test('knee pain without running does not trigger knee patterns', () {
        final result = CompensationDetectionService.detectCompensations({
          'occupation': 'active',
          'sittingHours': 'lt2',
          'neckPain': false,
          'lowerBackPain': false,
          'kneePain': true,
          'isRunner': false,
          'anklePain': false,
          'shoulderPainOverhead': false,
        });

        expect(result, isNot(contains(CompensationPattern.kneeValgus)));
      });

      test('detects ankle patterns for ankle pain', () {
        final result = CompensationDetectionService.detectCompensations({
          'occupation': 'active',
          'sittingHours': 'lt2',
          'neckPain': false,
          'lowerBackPain': false,
          'kneePain': false,
          'isRunner': false,
          'anklePain': true,
          'shoulderPainOverhead': false,
        });

        expect(
            result,
            containsAll([
              CompensationPattern.limitedDorsiflexion,
              CompensationPattern.overPronation,
            ]));
      });

      test('deduplicates patterns when multiple rules match same pattern', () {
        // Both desk+neckPain and shoulderOverhead produce roundedShoulders
        final result = CompensationDetectionService.detectCompensations({
          'occupation': 'desk',
          'sittingHours': '2to4',
          'neckPain': true,
          'lowerBackPain': false,
          'kneePain': false,
          'isRunner': false,
          'anklePain': false,
          'shoulderPainOverhead': true,
        });

        final roundedCount = result
            .where((p) => p == CompensationPattern.roundedShoulders)
            .length;
        expect(roundedCount, 1);
      });
    });

    group('calculateOverallScore', () {
      test('returns 10.0 for no compensations', () {
        expect(
          CompensationDetectionService.calculateOverallScore([]),
          10.0,
        );
      });

      test('returns 8.0 for 1-2 compensations', () {
        expect(
          CompensationDetectionService.calculateOverallScore([
            CompensationPattern.forwardHeadPosture,
          ]),
          8.0,
        );
      });

      test('returns 4.0 for 5 or more compensations', () {
        expect(
          CompensationDetectionService.calculateOverallScore([
            CompensationPattern.forwardHeadPosture,
            CompensationPattern.roundedShoulders,
            CompensationPattern.anteriorPelvicTilt,
            CompensationPattern.poorCoreStability,
            CompensationPattern.kneeValgus,
          ]),
          4.0,
        );
      });
    });
  });
}
