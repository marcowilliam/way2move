import 'package:flutter_test/flutter_test.dart';

import '../entities/assessment.dart';
import '../entities/detected_compensation.dart';
import '../entities/pose_frame.dart';
import '../entities/pose_landmark.dart';
import '../entities/video_analysis.dart';
import 'video_compensation_detector.dart';

// ── Frame-builder helpers ─────────────────────────────────────────────────────

/// Builds a [PoseLandmark] with full visibility.
PoseLandmark _lm(JointLandmark joint, double x, double y, {double z = 0.0}) =>
    PoseLandmark(joint: joint, x: x, y: y, z: z, visibility: 1.0);

/// A frame with all landmarks set to neutral alignment (no compensations).
PoseFrame _neutralOverheadSquatFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        // Knees above ankles, centred — no valgus
        _lm(JointLandmark.leftKnee, 0.35, 0.60),
        _lm(JointLandmark.leftAnkle, 0.35, 0.80),
        _lm(JointLandmark.rightKnee, 0.65, 0.60),
        _lm(JointLandmark.rightAnkle, 0.65, 0.80),
        // Heels at ankle level — no heel rise
        _lm(JointLandmark.leftHeel, 0.33, 0.82),
        _lm(JointLandmark.rightHeel, 0.67, 0.82),
        // Nose inline with shoulders — no forward head
        _lm(JointLandmark.nose, 0.50, 0.10),
        _lm(JointLandmark.leftShoulder, 0.40, 0.30),
        _lm(JointLandmark.rightShoulder, 0.60, 0.30),
      ],
    );

/// A frame where the left knee caves inward past the left ankle.
PoseFrame _kneeValgusFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        // Left knee (x=0.45) is notably right of left ankle (x=0.35) → valgus
        _lm(JointLandmark.leftKnee, 0.45, 0.60),
        _lm(JointLandmark.leftAnkle, 0.35, 0.80),
        _lm(JointLandmark.rightKnee, 0.55, 0.60),
        _lm(JointLandmark.rightAnkle, 0.65, 0.80),
        _lm(JointLandmark.leftHeel, 0.33, 0.82),
        _lm(JointLandmark.rightHeel, 0.67, 0.82),
        _lm(JointLandmark.nose, 0.50, 0.10),
        _lm(JointLandmark.leftShoulder, 0.40, 0.30),
        _lm(JointLandmark.rightShoulder, 0.60, 0.30),
      ],
    );

/// A frame where both heels rise above the ankle baseline → limited dorsiflexion.
PoseFrame _heelRiseFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        _lm(JointLandmark.leftKnee, 0.35, 0.60),
        _lm(JointLandmark.leftAnkle, 0.35, 0.80),
        _lm(JointLandmark.rightKnee, 0.65, 0.60),
        _lm(JointLandmark.rightAnkle, 0.65, 0.80),
        // Heels raised: y < ankle y by more than threshold
        _lm(JointLandmark.leftHeel, 0.33, 0.72),
        _lm(JointLandmark.rightHeel, 0.67, 0.72),
        _lm(JointLandmark.nose, 0.50, 0.10),
        _lm(JointLandmark.leftShoulder, 0.40, 0.30),
        _lm(JointLandmark.rightShoulder, 0.60, 0.30),
      ],
    );

/// A frame for single-leg stance where the pelvis drops (hip asymmetry > 5%).
PoseFrame _pelvicDropFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        // Left hip notably lower than right hip (y is larger = lower in image)
        _lm(JointLandmark.leftHip, 0.40, 0.55),
        _lm(JointLandmark.rightHip, 0.60, 0.48),
        _lm(JointLandmark.nose, 0.50, 0.10),
        _lm(JointLandmark.leftShoulder, 0.40, 0.30),
        _lm(JointLandmark.rightShoulder, 0.60, 0.30),
      ],
    );

/// A neutral single-leg stance frame (hips level).
PoseFrame _neutralSingleLegFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        _lm(JointLandmark.leftHip, 0.40, 0.50),
        _lm(JointLandmark.rightHip, 0.60, 0.50),
        _lm(JointLandmark.nose, 0.50, 0.10),
        _lm(JointLandmark.leftShoulder, 0.40, 0.30),
        _lm(JointLandmark.rightShoulder, 0.60, 0.30),
      ],
    );

/// A frame for shoulder raise where the arm fails to reach 160° elevation.
PoseFrame _roundedShouldersFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        // Low elbow: shoulder angle (hip→shoulder→elbow) well below 160°
        _lm(JointLandmark.leftShoulder, 0.40, 0.30),
        _lm(JointLandmark.leftElbow, 0.38, 0.45), // elbow barely raised
        _lm(JointLandmark.leftHip, 0.40, 0.60),
        _lm(JointLandmark.rightShoulder, 0.60, 0.30),
        _lm(JointLandmark.rightElbow, 0.62, 0.45),
        _lm(JointLandmark.rightHip, 0.60, 0.60),
        _lm(JointLandmark.nose, 0.50, 0.10),
      ],
    );

/// A frame for shoulder raise with good overhead elevation (≥ 160°).
PoseFrame _goodShoulderRaiseFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        _lm(JointLandmark.leftShoulder, 0.40, 0.30),
        // Elbow above and beside shoulder → large arm elevation angle
        _lm(JointLandmark.leftElbow, 0.38, 0.10),
        _lm(JointLandmark.leftHip, 0.40, 0.60),
        _lm(JointLandmark.rightShoulder, 0.60, 0.30),
        _lm(JointLandmark.rightElbow, 0.62, 0.10),
        _lm(JointLandmark.rightHip, 0.60, 0.60),
        _lm(JointLandmark.nose, 0.50, 0.10),
      ],
    );

/// A frame where the nose protrudes beyond 15 % of shoulder width from centre.
PoseFrame _forwardHeadPostureFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        _lm(JointLandmark.leftShoulder, 0.35, 0.30),
        _lm(JointLandmark.rightShoulder, 0.65, 0.30),
        // shoulderWidth = 0.30; midShoulder = 0.50; threshold = 0.045
        // nose at 0.60 → deviation = 0.10 > 0.045
        _lm(JointLandmark.nose, 0.60, 0.10),
      ],
    );

/// A frame with the nose centred between shoulders — no forward head posture.
PoseFrame _centredHeadFrame() => PoseFrame(
      timestamp: Duration.zero,
      landmarks: [
        _lm(JointLandmark.leftShoulder, 0.35, 0.30),
        _lm(JointLandmark.rightShoulder, 0.65, 0.30),
        _lm(JointLandmark.nose, 0.50, 0.10), // centred
      ],
    );

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Creates a list with [count] copies of [frame].
List<PoseFrame> _frames(PoseFrame frame, int count) =>
    List.generate(count, (_) => frame);

/// Mixed list: [affected] frames triggering the compensation + [clear] neutral
/// frames for the same movement.
List<PoseFrame> _mixed({
  required PoseFrame affected,
  required PoseFrame clear,
  required int affectedCount,
  required int clearCount,
}) =>
    [
      ..._frames(affected, affectedCount),
      ..._frames(clear, clearCount),
    ];

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VideoCompensationDetector', () {
    // ── kneeValgus ─────────────────────────────────────────────────────────

    group('overheadSquat / kneeValgus', () {
      test('detects kneeValgus when knee caves inward in every frame', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_kneeValgusFrame(), 10),
          movement: ScreeningMovement.overheadSquat,
        );

        expect(
          detections.any((d) => d.pattern == CompensationPattern.kneeValgus),
          isTrue,
        );
      });

      test('does NOT detect kneeValgus for perfectly neutral alignment', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_neutralOverheadSquatFrame(), 10),
          movement: ScreeningMovement.overheadSquat,
        );

        expect(
          detections.any((d) => d.pattern == CompensationPattern.kneeValgus),
          isFalse,
        );
      });

      test('severity is mild when valgus appears in < 30 % of frames', () {
        // 2 affected out of 10 total = 20 % → mild
        final detections = VideoCompensationDetector.detect(
          frames: _mixed(
            affected: _kneeValgusFrame(),
            clear: _neutralOverheadSquatFrame(),
            affectedCount: 2,
            clearCount: 8,
          ),
          movement: ScreeningMovement.overheadSquat,
        );

        final valgus = detections
            .where((d) => d.pattern == CompensationPattern.kneeValgus)
            .toList();
        expect(valgus.length, 1);
        expect(valgus.first.severity, CompensationSeverity.mild);
      });

      test('severity is moderate when valgus appears in 30–60 % of frames', () {
        // 4 affected out of 10 = 40 % → moderate
        final detections = VideoCompensationDetector.detect(
          frames: _mixed(
            affected: _kneeValgusFrame(),
            clear: _neutralOverheadSquatFrame(),
            affectedCount: 4,
            clearCount: 6,
          ),
          movement: ScreeningMovement.overheadSquat,
        );

        final valgus = detections
            .where((d) => d.pattern == CompensationPattern.kneeValgus)
            .toList();
        expect(valgus.first.severity, CompensationSeverity.moderate);
      });

      test('severity is significant when valgus appears in > 60 % of frames',
          () {
        // 7 affected out of 10 = 70 % → significant
        final detections = VideoCompensationDetector.detect(
          frames: _mixed(
            affected: _kneeValgusFrame(),
            clear: _neutralOverheadSquatFrame(),
            affectedCount: 7,
            clearCount: 3,
          ),
          movement: ScreeningMovement.overheadSquat,
        );

        final valgus = detections
            .where((d) => d.pattern == CompensationPattern.kneeValgus)
            .toList();
        expect(valgus.first.severity, CompensationSeverity.significant);
      });
    });

    // ── limitedDorsiflexion ────────────────────────────────────────────────

    group('overheadSquat / limitedDorsiflexion', () {
      test('detects limitedDorsiflexion when heels rise above ankle', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_heelRiseFrame(), 10),
          movement: ScreeningMovement.overheadSquat,
        );

        expect(
          detections
              .any((d) => d.pattern == CompensationPattern.limitedDorsiflexion),
          isTrue,
        );
      });

      test('does NOT detect limitedDorsiflexion when heels are grounded', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_neutralOverheadSquatFrame(), 10),
          movement: ScreeningMovement.overheadSquat,
        );

        expect(
          detections
              .any((d) => d.pattern == CompensationPattern.limitedDorsiflexion),
          isFalse,
        );
      });
    });

    // ── weakGluteMed ──────────────────────────────────────────────────────

    group('singleLegStance / weakGluteMed', () {
      test('detects weakGluteMed when pelvis drops beyond threshold', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_pelvicDropFrame(), 10),
          movement: ScreeningMovement.singleLegStance,
        );

        expect(
          detections.any((d) => d.pattern == CompensationPattern.weakGluteMed),
          isTrue,
        );
      });

      test('does NOT detect weakGluteMed when hips are level', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_neutralSingleLegFrame(), 10),
          movement: ScreeningMovement.singleLegStance,
        );

        expect(
          detections.any((d) => d.pattern == CompensationPattern.weakGluteMed),
          isFalse,
        );
      });
    });

    // ── roundedShoulders ──────────────────────────────────────────────────

    group('shoulderRaise / roundedShoulders', () {
      test('detects roundedShoulders when arm elevation is below 160°', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_roundedShouldersFrame(), 10),
          movement: ScreeningMovement.shoulderRaise,
        );

        expect(
          detections
              .any((d) => d.pattern == CompensationPattern.roundedShoulders),
          isTrue,
        );
      });

      test('does NOT detect roundedShoulders with good overhead elevation', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_goodShoulderRaiseFrame(), 10),
          movement: ScreeningMovement.shoulderRaise,
        );

        expect(
          detections
              .any((d) => d.pattern == CompensationPattern.roundedShoulders),
          isFalse,
        );
      });
    });

    // ── forwardHeadPosture (any movement) ─────────────────────────────────

    group('forwardHeadPosture', () {
      for (final movement in ScreeningMovement.values) {
        test('detects forwardHeadPosture during ${movement.name}', () {
          final detections = VideoCompensationDetector.detect(
            frames: _frames(_forwardHeadPostureFrame(), 10),
            movement: movement,
          );

          expect(
            detections.any(
                (d) => d.pattern == CompensationPattern.forwardHeadPosture),
            isTrue,
            reason: 'Expected forwardHeadPosture for movement ${movement.name}',
          );
        });
      }

      test('does NOT detect forwardHeadPosture when head is centred', () {
        // Use a movement that has no other detections: singleLegStance
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_centredHeadFrame(), 10),
          movement: ScreeningMovement.singleLegStance,
        );

        expect(
          detections
              .any((d) => d.pattern == CompensationPattern.forwardHeadPosture),
          isFalse,
        );
      });
    });

    // ── Edge cases ────────────────────────────────────────────────────────

    group('edge cases', () {
      test('returns empty list when frames list is empty', () {
        final detections = VideoCompensationDetector.detect(
          frames: const [],
          movement: ScreeningMovement.overheadSquat,
        );
        expect(detections, isEmpty);
      });

      test('ignores frames where required landmarks are missing', () {
        // Frame with no landmarks — detector must not throw
        const emptyFrame = PoseFrame(
          timestamp: Duration.zero,
          landmarks: [],
        );
        expect(
          () => VideoCompensationDetector.detect(
            frames: [emptyFrame],
            movement: ScreeningMovement.overheadSquat,
          ),
          returnsNormally,
        );
      });

      test('ignores landmarks with visibility below 0.5', () {
        // kneeValgus frame but with all landmarks having low visibility
        const lowVisFrame = PoseFrame(
          timestamp: Duration.zero,
          landmarks: [
            PoseLandmark(
              joint: JointLandmark.leftKnee,
              x: 0.45,
              y: 0.60,
              z: 0.0,
              visibility: 0.4, // below threshold
            ),
            PoseLandmark(
              joint: JointLandmark.leftAnkle,
              x: 0.35,
              y: 0.80,
              z: 0.0,
              visibility: 0.4,
            ),
          ],
        );

        final detections = VideoCompensationDetector.detect(
          frames: [lowVisFrame],
          movement: ScreeningMovement.overheadSquat,
        );
        expect(
          detections.any((d) => d.pattern == CompensationPattern.kneeValgus),
          isFalse,
        );
      });

      test('each detection records correct total frame count', () {
        final detections = VideoCompensationDetector.detect(
          frames: _frames(_kneeValgusFrame(), 15),
          movement: ScreeningMovement.overheadSquat,
        );
        final valgus = detections
            .firstWhere((d) => d.pattern == CompensationPattern.kneeValgus);
        expect(valgus.totalFrameCount, 15);
        expect(valgus.affectedFrameCount, 15);
      });
    });
  });
}
