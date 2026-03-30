/// MediaPipe BlazePose landmark index → domain joint mapping.
/// Uses official MediaPipe 33-landmark numbering.
enum JointLandmark {
  nose(0),
  leftShoulder(11),
  rightShoulder(12),
  leftElbow(13),
  rightElbow(14),
  leftWrist(15),
  rightWrist(16),
  leftHip(23),
  rightHip(24),
  leftKnee(25),
  rightKnee(26),
  leftAnkle(27),
  rightAnkle(28),
  leftHeel(29),
  rightHeel(30),
  leftFootIndex(31),
  rightFootIndex(32);

  const JointLandmark(this.mediaPipeIndex);

  /// The MediaPipe landmark index this joint maps to.
  final int mediaPipeIndex;

  /// Returns the [JointLandmark] for a given MediaPipe index, or null if
  /// the index is not one of the joints tracked by this app.
  static JointLandmark? fromMediaPipeIndex(int index) {
    for (final joint in values) {
      if (joint.mediaPipeIndex == index) return joint;
    }
    return null;
  }
}

/// A single detected landmark from a pose frame.
///
/// Coordinates are normalised to [0.0, 1.0] relative to the frame dimensions.
/// [z] is depth relative to the hip mid-point (negative = closer to camera).
/// [visibility] is in [0.0, 1.0]; values < 0.5 are generally considered
/// unreliable and should be excluded from angle calculations.
class PoseLandmark {
  final JointLandmark joint;
  final double x;
  final double y;
  final double z;
  final double visibility;

  const PoseLandmark({
    required this.joint,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  /// True when the landmark is considered reliably visible.
  bool get isVisible => visibility >= 0.5;

  @override
  bool operator ==(Object other) =>
      other is PoseLandmark && other.joint == joint;

  @override
  int get hashCode => joint.hashCode;

  @override
  String toString() =>
      'PoseLandmark(${joint.name}, x=$x, y=$y, z=$z, vis=$visibility)';
}
