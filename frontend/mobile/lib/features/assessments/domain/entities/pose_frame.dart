import 'dart:math' as math;

import 'pose_landmark.dart';

/// A snapshot of all detected landmarks at a single point in time during
/// a movement recording.
class PoseFrame {
  final Duration timestamp;
  final List<PoseLandmark> landmarks;

  const PoseFrame({
    required this.timestamp,
    required this.landmarks,
  });

  /// Returns the landmark for [joint], or null if not present in this frame.
  PoseLandmark? landmarkFor(JointLandmark joint) {
    for (final lm in landmarks) {
      if (lm.joint == joint) return lm;
    }
    return null;
  }

  /// Calculates the angle (in degrees) at [vertex] formed by the vectors
  /// [vertex]→[pointA] and [vertex]→[pointB].
  ///
  /// Returns null if any of the three joints are missing or not reliably
  /// visible in this frame.
  double? angleDegrees(
    JointLandmark pointA,
    JointLandmark vertex,
    JointLandmark pointB,
  ) {
    final a = landmarkFor(pointA);
    final v = landmarkFor(vertex);
    final b = landmarkFor(pointB);

    if (a == null || v == null || b == null) return null;
    if (!a.isVisible || !v.isVisible || !b.isVisible) return null;

    // 2-D vectors from vertex
    final ax = a.x - v.x;
    final ay = a.y - v.y;
    final bx = b.x - v.x;
    final by = b.y - v.y;

    final dot = ax * bx + ay * by;
    final magA = math.sqrt(ax * ax + ay * ay);
    final magB = math.sqrt(bx * bx + by * by);

    if (magA == 0 || magB == 0) return null;

    // Clamp to [-1, 1] to guard against floating-point rounding
    final cosAngle = (dot / (magA * magB)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * (180.0 / math.pi);
  }

  /// Returns the horizontal offset of [jointA] relative to [jointB].
  ///
  /// Positive means [jointA] is to the right of [jointB] in normalised space.
  /// Returns null if either landmark is missing or not visible.
  double? horizontalOffset(JointLandmark jointA, JointLandmark jointB) {
    final a = landmarkFor(jointA);
    final b = landmarkFor(jointB);
    if (a == null || b == null) return null;
    if (!a.isVisible || !b.isVisible) return null;
    return a.x - b.x;
  }

  /// Returns the vertical offset of [jointA] relative to [jointB].
  ///
  /// Positive means [jointA] is below [jointB] in normalised space
  /// (y increases downward in image coordinates).
  /// Returns null if either landmark is missing or not visible.
  double? verticalOffset(JointLandmark jointA, JointLandmark jointB) {
    final a = landmarkFor(jointA);
    final b = landmarkFor(jointB);
    if (a == null || b == null) return null;
    if (!a.isVisible || !b.isVisible) return null;
    return a.y - b.y;
  }
}
