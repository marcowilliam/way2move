import 'package:flutter/material.dart';

import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/entities/detected_compensation.dart';
import 'package:way2move/features/assessments/domain/entities/pose_landmark.dart';

/// Standard skeleton connections between [JointLandmark] pairs.
const List<(JointLandmark, JointLandmark)> _skeletonConnections = [
  // Upper body
  (JointLandmark.leftShoulder, JointLandmark.rightShoulder),
  (JointLandmark.leftShoulder, JointLandmark.leftElbow),
  (JointLandmark.leftElbow, JointLandmark.leftWrist),
  (JointLandmark.rightShoulder, JointLandmark.rightElbow),
  (JointLandmark.rightElbow, JointLandmark.rightWrist),
  // Torso
  (JointLandmark.leftShoulder, JointLandmark.leftHip),
  (JointLandmark.rightShoulder, JointLandmark.rightHip),
  (JointLandmark.leftHip, JointLandmark.rightHip),
  // Lower body
  (JointLandmark.leftHip, JointLandmark.leftKnee),
  (JointLandmark.leftKnee, JointLandmark.leftAnkle),
  (JointLandmark.rightHip, JointLandmark.rightKnee),
  (JointLandmark.rightKnee, JointLandmark.rightAnkle),
  (JointLandmark.leftAnkle, JointLandmark.leftHeel),
  (JointLandmark.rightAnkle, JointLandmark.rightHeel),
  (JointLandmark.leftHeel, JointLandmark.leftFootIndex),
  (JointLandmark.rightHeel, JointLandmark.rightFootIndex),
];

/// Returns the color for a given joint based on whether compensations
/// are detected at that joint.
Color _colorForJoint(
  JointLandmark joint,
  List<DetectedCompensation> compensations,
) {
  // Map compensation patterns to affected joints (simplified heuristic)
  final affectedJoints = <JointLandmark>{};

  for (final comp in compensations) {
    switch (comp.pattern) {
      case CompensationPattern.kneeValgus:
        affectedJoints.addAll([
          JointLandmark.leftKnee,
          JointLandmark.rightKnee,
        ]);
      case CompensationPattern.overPronation:
        affectedJoints.addAll([
          JointLandmark.leftAnkle,
          JointLandmark.rightAnkle,
          JointLandmark.leftHeel,
          JointLandmark.rightHeel,
        ]);
      case CompensationPattern.limitedDorsiflexion:
        affectedJoints.addAll([
          JointLandmark.leftAnkle,
          JointLandmark.rightAnkle,
        ]);
      case CompensationPattern.anteriorPelvicTilt:
      case CompensationPattern.posteriorPelvicTilt:
        affectedJoints.addAll([
          JointLandmark.leftHip,
          JointLandmark.rightHip,
        ]);
      case CompensationPattern.forwardHeadPosture:
        affectedJoints.add(JointLandmark.nose);
      case CompensationPattern.roundedShoulders:
        affectedJoints.addAll([
          JointLandmark.leftShoulder,
          JointLandmark.rightShoulder,
        ]);
      case CompensationPattern.weakGluteMed:
        affectedJoints.addAll([
          JointLandmark.leftHip,
          JointLandmark.rightHip,
        ]);
      default:
        break;
    }
  }

  if (!affectedJoints.contains(joint)) return const Color(0xFF4CAF50); // green

  // Determine worst severity for this joint
  CompensationSeverity? worst;
  for (final comp in compensations) {
    final worstIndex = worst?.index ?? -1;
    if (comp.severity.index > worstIndex) {
      worst = comp.severity;
    }
  }

  return switch (worst) {
    CompensationSeverity.significant => const Color(0xFFF44336), // red
    CompensationSeverity.moderate => const Color(0xFFFF9800), // amber
    _ => const Color(0xFFFF9800), // amber for mild with affectedJoint
  };
}

/// A [CustomPainter] that draws a pose skeleton overlay on top of a video frame.
///
/// Draws:
/// - Colored dots at each visible joint
/// - Lines connecting standard skeleton joints
///
/// Color coding:
/// - Green: good alignment (no compensation detected at joint)
/// - Amber: borderline (mild/moderate compensation)
/// - Red: compensation detected (significant)
class _PosePainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final List<DetectedCompensation> compensations;

  _PosePainter({required this.landmarks, required this.compensations});

  @override
  void paint(Canvas canvas, Size size) {
    final jointMap = {for (final lm in landmarks) lm.joint: lm};

    // Draw connections
    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.6);

    for (final (from, to) in _skeletonConnections) {
      final a = jointMap[from];
      final b = jointMap[to];
      if (a == null || b == null) continue;
      if (!a.isVisible || !b.isVisible) continue;

      canvas.drawLine(
        Offset(a.x * size.width, a.y * size.height),
        Offset(b.x * size.width, b.y * size.height),
        linePaint,
      );
    }

    // Draw joint dots
    for (final lm in landmarks) {
      if (!lm.isVisible) continue;

      final color = _colorForJoint(lm.joint, compensations);
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final center = Offset(lm.x * size.width, lm.y * size.height);
      canvas.drawCircle(center, 6, dotPaint);
      canvas.drawCircle(center, 6, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_PosePainter oldDelegate) =>
      oldDelegate.landmarks != landmarks ||
      oldDelegate.compensations != compensations;
}

/// Widget that overlays a pose skeleton on top of its [child].
///
/// Pass [landmarks] from a [PoseFrame] and [compensations] from a
/// [CompensationReport] to drive the color coding.
class PoseLandmarkOverlay extends StatelessWidget {
  final List<PoseLandmark> landmarks;
  final List<DetectedCompensation> compensations;
  final Widget child;

  const PoseLandmarkOverlay({
    super.key,
    required this.landmarks,
    required this.compensations,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        CustomPaint(
          painter: _PosePainter(
            landmarks: landmarks,
            compensations: compensations,
          ),
        ),
      ],
    );
  }
}
