import 'package:flutter_test/flutter_test.dart';
import 'pose_frame.dart';
import 'pose_landmark.dart';

// Helper to create a visible landmark at given (x, y).
PoseLandmark _lm(JointLandmark joint, double x, double y) => PoseLandmark(
      joint: joint,
      x: x,
      y: y,
      z: 0.0,
      visibility: 0.9,
    );

// Helper to create a low-visibility landmark.
PoseLandmark _hidden(JointLandmark joint) => PoseLandmark(
      joint: joint,
      x: 0.5,
      y: 0.5,
      z: 0.0,
      visibility: 0.2,
    );

void main() {
  group('PoseFrame.landmarkFor', () {
    test('returns the landmark for a present joint', () {
      final lm = _lm(JointLandmark.leftKnee, 0.5, 0.7);
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [lm],
      );
      expect(frame.landmarkFor(JointLandmark.leftKnee), equals(lm));
    });

    test('returns null for a missing joint', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [_lm(JointLandmark.leftKnee, 0.5, 0.7)],
      );
      expect(frame.landmarkFor(JointLandmark.rightKnee), isNull);
    });
  });

  group('PoseFrame.angleDegrees', () {
    // Straight line: A at (0,0), vertex at (1,0), B at (2,0) → 180°
    test('returns 180 for a straight line', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [
          _lm(JointLandmark.leftAnkle, 0.0, 0.0),
          _lm(JointLandmark.leftKnee, 1.0, 0.0),
          _lm(JointLandmark.leftHip, 2.0, 0.0),
        ],
      );
      final angle = frame.angleDegrees(
        JointLandmark.leftAnkle,
        JointLandmark.leftKnee,
        JointLandmark.leftHip,
      );
      expect(angle, closeTo(180.0, 0.001));
    });

    // Right angle: A at (0,1), vertex at (0,0), B at (1,0) → 90°
    test('returns 90 for a right angle', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [
          _lm(JointLandmark.leftAnkle, 0.0, 1.0),
          _lm(JointLandmark.leftKnee, 0.0, 0.0),
          _lm(JointLandmark.leftHip, 1.0, 0.0),
        ],
      );
      final angle = frame.angleDegrees(
        JointLandmark.leftAnkle,
        JointLandmark.leftKnee,
        JointLandmark.leftHip,
      );
      expect(angle, closeTo(90.0, 0.001));
    });

    // 45° angle
    test('returns approximately 45 for a 45° angle', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [
          _lm(JointLandmark.leftAnkle, 1.0, 0.0),
          _lm(JointLandmark.leftKnee, 0.0, 0.0),
          _lm(JointLandmark.leftHip, 1.0, 1.0),
        ],
      );
      final angle = frame.angleDegrees(
        JointLandmark.leftAnkle,
        JointLandmark.leftKnee,
        JointLandmark.leftHip,
      );
      expect(angle, closeTo(45.0, 0.001));
    });

    test('returns null when a landmark is missing', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [
          _lm(JointLandmark.leftAnkle, 0.0, 0.0),
          _lm(JointLandmark.leftKnee, 1.0, 0.0),
          // leftHip missing
        ],
      );
      expect(
        frame.angleDegrees(
          JointLandmark.leftAnkle,
          JointLandmark.leftKnee,
          JointLandmark.leftHip,
        ),
        isNull,
      );
    });

    test('returns null when a landmark is not visible', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [
          _lm(JointLandmark.leftAnkle, 0.0, 0.0),
          _lm(JointLandmark.leftKnee, 1.0, 0.0),
          _hidden(JointLandmark.leftHip),
        ],
      );
      expect(
        frame.angleDegrees(
          JointLandmark.leftAnkle,
          JointLandmark.leftKnee,
          JointLandmark.leftHip,
        ),
        isNull,
      );
    });
  });

  group('PoseFrame.horizontalOffset', () {
    test('returns positive when jointA is to the right of jointB', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [
          _lm(JointLandmark.leftKnee, 0.6, 0.5),
          _lm(JointLandmark.leftAnkle, 0.4, 0.8),
        ],
      );
      final offset = frame.horizontalOffset(
        JointLandmark.leftKnee,
        JointLandmark.leftAnkle,
      );
      expect(offset, closeTo(0.2, 0.001));
    });

    test('returns null when a joint is missing', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [_lm(JointLandmark.leftKnee, 0.5, 0.5)],
      );
      expect(
        frame.horizontalOffset(
          JointLandmark.leftKnee,
          JointLandmark.rightKnee,
        ),
        isNull,
      );
    });
  });

  group('PoseFrame.verticalOffset', () {
    test('returns positive when jointA is below jointB (y increases down)', () {
      final frame = PoseFrame(
        timestamp: Duration.zero,
        landmarks: [
          _lm(JointLandmark.leftHip, 0.5, 0.7),
          _lm(JointLandmark.leftShoulder, 0.5, 0.3),
        ],
      );
      final offset = frame.verticalOffset(
        JointLandmark.leftHip,
        JointLandmark.leftShoulder,
      );
      expect(offset, closeTo(0.4, 0.001));
    });
  });
}
