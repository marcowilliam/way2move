import 'package:flutter_test/flutter_test.dart';
import 'pose_landmark.dart';

void main() {
  group('JointLandmark', () {
    test('fromMediaPipeIndex returns correct joint for known index', () {
      expect(JointLandmark.fromMediaPipeIndex(11), JointLandmark.leftShoulder);
      expect(JointLandmark.fromMediaPipeIndex(25), JointLandmark.leftKnee);
      expect(JointLandmark.fromMediaPipeIndex(0), JointLandmark.nose);
      expect(JointLandmark.fromMediaPipeIndex(32), JointLandmark.rightFootIndex);
    });

    test('fromMediaPipeIndex returns null for unmapped index', () {
      expect(JointLandmark.fromMediaPipeIndex(1), isNull);
      expect(JointLandmark.fromMediaPipeIndex(99), isNull);
    });

    test('each joint has a unique mediaPipeIndex', () {
      final indices = JointLandmark.values.map((j) => j.mediaPipeIndex).toList();
      expect(indices.toSet().length, equals(indices.length));
    });

    test('mediaPipeIndex values match MediaPipe BlazePose spec', () {
      expect(JointLandmark.leftHip.mediaPipeIndex, 23);
      expect(JointLandmark.rightHip.mediaPipeIndex, 24);
      expect(JointLandmark.leftKnee.mediaPipeIndex, 25);
      expect(JointLandmark.rightKnee.mediaPipeIndex, 26);
      expect(JointLandmark.leftAnkle.mediaPipeIndex, 27);
      expect(JointLandmark.rightAnkle.mediaPipeIndex, 28);
    });
  });

  group('PoseLandmark', () {
    test('isVisible is true when visibility >= 0.5', () {
      const visible = PoseLandmark(
        joint: JointLandmark.leftKnee,
        x: 0.5,
        y: 0.5,
        z: 0.0,
        visibility: 0.8,
      );
      expect(visible.isVisible, isTrue);
    });

    test('isVisible is false when visibility < 0.5', () {
      const hidden = PoseLandmark(
        joint: JointLandmark.leftKnee,
        x: 0.5,
        y: 0.5,
        z: 0.0,
        visibility: 0.3,
      );
      expect(hidden.isVisible, isFalse);
    });

    test('isVisible is true at exactly 0.5', () {
      const borderline = PoseLandmark(
        joint: JointLandmark.leftKnee,
        x: 0.5,
        y: 0.5,
        z: 0.0,
        visibility: 0.5,
      );
      expect(borderline.isVisible, isTrue);
    });

    test('equality is based on joint only', () {
      const a = PoseLandmark(
        joint: JointLandmark.leftKnee,
        x: 0.1,
        y: 0.2,
        z: 0.0,
        visibility: 0.9,
      );
      const b = PoseLandmark(
        joint: JointLandmark.leftKnee,
        x: 0.9,
        y: 0.8,
        z: 0.0,
        visibility: 0.6,
      );
      expect(a, equals(b));
    });
  });
}
