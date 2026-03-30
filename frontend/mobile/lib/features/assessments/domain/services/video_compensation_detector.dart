import '../entities/assessment.dart';
import '../entities/detected_compensation.dart';
import '../entities/pose_frame.dart';
import '../entities/pose_landmark.dart';
import '../entities/video_analysis.dart';

// ── Threshold constants ───────────────────────────────────────────────────────

/// Normalised horizontal distance a knee must travel inward past its same-side
/// ankle to be flagged as knee valgus.
///
/// Positive = knee is medially displaced.
/// Value of 0.04 corresponds to ~4 % of frame width, empirically equivalent
/// to the ~10° inward deviation described in the phase 2 spec.
const double _kneeValgusThreshold = 0.04;

/// A heel is considered raised when its y-coordinate (image space, increasing
/// downward) is higher than the same-side ankle by this amount in normalised
/// units.  0.04 ≈ 4 % of frame height, sufficient to flag visible heel rise.
const double _heelRiseThreshold = 0.04;

/// Pelvis drop threshold in normalised y-units.  An asymmetry > 0.05 (5 % of
/// frame height) between left and right hip y-coordinates indicates weak
/// glute med / Trendelenburg pattern.
const double _pelvicDropThreshold = 0.05;

/// Minimum arm-elevation angle (hip→shoulder→elbow) in degrees.  Below this
/// value at peak overhead raise indicates rounded shoulders / restricted
/// thoracic mobility.
const double _shoulderElevationMinDegrees = 160.0;

/// A head is considered forward when the nose deviates horizontally from the
/// mid-shoulder centre by more than this fraction of total shoulder width.
const double _forwardHeadRatio = 0.15;

// ── Detector ─────────────────────────────────────────────────────────────────

/// Pure-Dart, on-device compensation detection from pose frames.
///
/// Call [detect] with the frames extracted from a single movement clip and the
/// movement type.  Returns a list of [DetectedCompensation] — one entry per
/// pattern that was triggered, with [DetectedCompensation.affectedFrameCount]
/// and [DetectedCompensation.totalFrameCount] set so that severity can be
/// derived from the frame ratio.
abstract class VideoCompensationDetector {
  /// Analyses [frames] for the given [movement] and returns any detected
  /// compensations.
  ///
  /// Returns an empty list when [frames] is empty or no compensation is found.
  static List<DetectedCompensation> detect({
    required List<PoseFrame> frames,
    required ScreeningMovement movement,
  }) {
    if (frames.isEmpty) return const [];

    final int total = frames.length;
    final detections = <CompensationPattern, int>{};

    // Per-frame evaluation
    for (final frame in frames) {
      // Forward head posture is evaluated for every movement.
      if (_hasForwardHeadPosture(frame)) {
        detections[CompensationPattern.forwardHeadPosture] =
            (detections[CompensationPattern.forwardHeadPosture] ?? 0) + 1;
      }

      switch (movement) {
        case ScreeningMovement.overheadSquat:
          if (_hasKneeValgus(frame)) {
            detections[CompensationPattern.kneeValgus] =
                (detections[CompensationPattern.kneeValgus] ?? 0) + 1;
          }
          if (_hasHeelRise(frame)) {
            detections[CompensationPattern.limitedDorsiflexion] =
                (detections[CompensationPattern.limitedDorsiflexion] ?? 0) + 1;
          }

        case ScreeningMovement.singleLegStance:
          if (_hasPelvicDrop(frame)) {
            detections[CompensationPattern.weakGluteMed] =
                (detections[CompensationPattern.weakGluteMed] ?? 0) + 1;
          }

        case ScreeningMovement.shoulderRaise:
          if (_hasRoundedShoulders(frame)) {
            detections[CompensationPattern.roundedShoulders] =
                (detections[CompensationPattern.roundedShoulders] ?? 0) + 1;
          }

        case ScreeningMovement.forwardBend:
        case ScreeningMovement.walkingGait:
          // Forward head posture already covered above; no additional rules yet.
          break;
      }
    }

    return detections.entries
        .where((e) => e.value > 0)
        .map((e) => DetectedCompensation(
              pattern: e.key,
              affectedFrameCount: e.value,
              totalFrameCount: total,
            ))
        .toList();
  }

  // ── Rule implementations ────────────────────────────────────────────────

  /// Left knee valgus: left knee x is significantly to the right of left ankle x.
  /// Right knee valgus: right knee x is significantly to the left of right ankle x.
  ///
  /// In normalised image coordinates, "to the right" = larger x value.
  static bool _hasKneeValgus(PoseFrame frame) {
    final leftKnee = frame.landmarkFor(JointLandmark.leftKnee);
    final leftAnkle = frame.landmarkFor(JointLandmark.leftAnkle);
    final rightKnee = frame.landmarkFor(JointLandmark.rightKnee);
    final rightAnkle = frame.landmarkFor(JointLandmark.rightAnkle);

    if (leftKnee != null &&
        leftAnkle != null &&
        leftKnee.isVisible &&
        leftAnkle.isVisible) {
      // Left knee caving rightward (toward midline)
      if (leftKnee.x - leftAnkle.x > _kneeValgusThreshold) return true;
    }

    if (rightKnee != null &&
        rightAnkle != null &&
        rightKnee.isVisible &&
        rightAnkle.isVisible) {
      // Right knee caving leftward (toward midline)
      if (rightAnkle.x - rightKnee.x > _kneeValgusThreshold) return true;
    }

    return false;
  }

  /// Heel rise: a heel's y coordinate is more than [_heelRiseThreshold] above
  /// (smaller y value) the same-side ankle.
  static bool _hasHeelRise(PoseFrame frame) {
    final leftHeel = frame.landmarkFor(JointLandmark.leftHeel);
    final leftAnkle = frame.landmarkFor(JointLandmark.leftAnkle);
    final rightHeel = frame.landmarkFor(JointLandmark.rightHeel);
    final rightAnkle = frame.landmarkFor(JointLandmark.rightAnkle);

    if (leftHeel != null &&
        leftAnkle != null &&
        leftHeel.isVisible &&
        leftAnkle.isVisible) {
      // heel.y < ankle.y means heel is higher in the image
      if (leftAnkle.y - leftHeel.y > _heelRiseThreshold) return true;
    }

    if (rightHeel != null &&
        rightAnkle != null &&
        rightHeel.isVisible &&
        rightAnkle.isVisible) {
      if (rightAnkle.y - rightHeel.y > _heelRiseThreshold) return true;
    }

    return false;
  }

  /// Pelvic drop (Trendelenburg): the absolute vertical difference between the
  /// left and right hip exceeds [_pelvicDropThreshold].
  static bool _hasPelvicDrop(PoseFrame frame) {
    final leftHip = frame.landmarkFor(JointLandmark.leftHip);
    final rightHip = frame.landmarkFor(JointLandmark.rightHip);

    if (leftHip == null || rightHip == null) return false;
    if (!leftHip.isVisible || !rightHip.isVisible) return false;

    return (leftHip.y - rightHip.y).abs() > _pelvicDropThreshold;
  }

  /// Rounded shoulders: evaluates the arm elevation angle at the shoulder
  /// (hip → shoulder → elbow) for both sides.  If either angle is below
  /// [_shoulderElevationMinDegrees], the frame is flagged.
  static bool _hasRoundedShoulders(PoseFrame frame) {
    final leftAngle = frame.angleDegrees(
      JointLandmark.leftHip,
      JointLandmark.leftShoulder,
      JointLandmark.leftElbow,
    );
    if (leftAngle != null && leftAngle < _shoulderElevationMinDegrees) {
      return true;
    }

    final rightAngle = frame.angleDegrees(
      JointLandmark.rightHip,
      JointLandmark.rightShoulder,
      JointLandmark.rightElbow,
    );
    if (rightAngle != null && rightAngle < _shoulderElevationMinDegrees) {
      return true;
    }

    return false;
  }

  /// Forward head posture: the nose deviates horizontally from the mid-shoulder
  /// centre by more than 15 % of the shoulder width.
  static bool _hasForwardHeadPosture(PoseFrame frame) {
    final nose = frame.landmarkFor(JointLandmark.nose);
    final leftShoulder = frame.landmarkFor(JointLandmark.leftShoulder);
    final rightShoulder = frame.landmarkFor(JointLandmark.rightShoulder);

    if (nose == null || leftShoulder == null || rightShoulder == null) {
      return false;
    }
    if (!nose.isVisible || !leftShoulder.isVisible || !rightShoulder.isVisible) {
      return false;
    }

    final shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();
    if (shoulderWidth == 0) return false;

    final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final deviation = (nose.x - midShoulderX).abs();

    return deviation > _forwardHeadRatio * shoulderWidth;
  }
}
