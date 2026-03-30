import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/assessment.dart';
import '../../domain/entities/pose_frame.dart';
import '../../domain/entities/pose_landmark.dart';
import '../../domain/entities/video_analysis.dart';

// ---------------------------------------------------------------------------
// PoseLandmark serialization helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _landmarkToMap(PoseLandmark lm) => {
      'joint': lm.joint.name,
      'x': lm.x,
      'y': lm.y,
      'z': lm.z,
      'visibility': lm.visibility,
    };

PoseLandmark _landmarkFromMap(Map<String, dynamic> m) => PoseLandmark(
      joint: JointLandmark.values.firstWhere((j) => j.name == m['joint']),
      x: (m['x'] as num).toDouble(),
      y: (m['y'] as num).toDouble(),
      z: (m['z'] as num).toDouble(),
      visibility: (m['visibility'] as num).toDouble(),
    );

// ---------------------------------------------------------------------------
// PoseFrame serialization helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _frameToMap(PoseFrame frame) => {
      'timestampMs': frame.timestamp.inMilliseconds,
      'landmarks': frame.landmarks.map(_landmarkToMap).toList(),
    };

PoseFrame _frameFromMap(Map<String, dynamic> m) => PoseFrame(
      timestamp: Duration(milliseconds: (m['timestampMs'] as num).toInt()),
      landmarks: (m['landmarks'] as List)
          .map((e) => _landmarkFromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );

// ---------------------------------------------------------------------------
// VideoAnalysisModel
// ---------------------------------------------------------------------------

class VideoAnalysisModel {
  final String id;
  final String assessmentId;
  final String userId;
  final String movementName;
  final List<Map<String, dynamic>> frames;
  final List<String> detectedCompensations;
  final String? storageVideoPath;
  final DateTime analyzedAt;

  const VideoAnalysisModel({
    required this.id,
    required this.assessmentId,
    required this.userId,
    required this.movementName,
    required this.frames,
    required this.detectedCompensations,
    required this.analyzedAt,
    this.storageVideoPath,
  });

  factory VideoAnalysisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoAnalysisModel(
      id: doc.id,
      assessmentId: data['assessmentId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      movementName: data['movementName'] as String? ?? '',
      frames: (data['frames'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      detectedCompensations:
          List<String>.from(data['detectedCompensations'] as List? ?? []),
      storageVideoPath: data['storageVideoPath'] as String?,
      analyzedAt: (data['analyzedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'assessmentId': assessmentId,
        'userId': userId,
        'movementName': movementName,
        'frames': frames,
        'detectedCompensations': detectedCompensations,
        if (storageVideoPath != null) 'storageVideoPath': storageVideoPath,
        'analyzedAt': Timestamp.fromDate(analyzedAt),
      };

  VideoAnalysis toEntity() => VideoAnalysis(
        id: id,
        assessmentId: assessmentId,
        userId: userId,
        movement: ScreeningMovement.values
            .firstWhere((m) => m.name == movementName),
        frames: frames.map(_frameFromMap).toList(),
        detectedCompensations: detectedCompensations
            .map((s) =>
                CompensationPattern.values.firstWhere((e) => e.name == s))
            .toList(),
        storageVideoPath: storageVideoPath,
        analyzedAt: analyzedAt,
      );

  factory VideoAnalysisModel.fromEntity(VideoAnalysis entity) =>
      VideoAnalysisModel(
        id: entity.id,
        assessmentId: entity.assessmentId,
        userId: entity.userId,
        movementName: entity.movement.name,
        frames: entity.frames.map(_frameToMap).toList(),
        detectedCompensations:
            entity.detectedCompensations.map((p) => p.name).toList(),
        storageVideoPath: entity.storageVideoPath,
        analyzedAt: entity.analyzedAt,
      );
}
