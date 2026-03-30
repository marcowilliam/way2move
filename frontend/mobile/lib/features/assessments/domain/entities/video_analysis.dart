import 'assessment.dart';
import 'pose_frame.dart';

/// The five screening movements used in the video assessment flow.
enum ScreeningMovement {
  overheadSquat,
  singleLegStance,
  forwardBend,
  shoulderRaise,
  walkingGait;

  String get displayName => switch (this) {
        ScreeningMovement.overheadSquat => 'Overhead Squat',
        ScreeningMovement.singleLegStance => 'Single-Leg Stance',
        ScreeningMovement.forwardBend => 'Forward Bend',
        ScreeningMovement.shoulderRaise => 'Shoulder Raise',
        ScreeningMovement.walkingGait => 'Walking Gait',
      };

  String get instruction => switch (this) {
        ScreeningMovement.overheadSquat =>
          'Stand with feet shoulder-width apart, arms overhead. '
              'Perform 3 slow squats.',
        ScreeningMovement.singleLegStance =>
          'Stand on one leg for 10 seconds, then switch.',
        ScreeningMovement.forwardBend =>
          'Stand tall, then slowly bend forward reaching toward the floor.',
        ScreeningMovement.shoulderRaise =>
          'Stand with arms at sides, slowly raise both arms overhead.',
        ScreeningMovement.walkingGait =>
          'Walk naturally toward the camera and back — 5 steps each way.',
      };

  /// Estimated duration hint shown to the user before recording.
  String get durationHint => switch (this) {
        ScreeningMovement.overheadSquat => '~10 sec',
        ScreeningMovement.singleLegStance => '~20 sec',
        ScreeningMovement.forwardBend => '~8 sec',
        ScreeningMovement.shoulderRaise => '~8 sec',
        ScreeningMovement.walkingGait => '~15 sec',
      };
}

/// Result of running the AI video analysis on a single screening movement clip.
class VideoAnalysis {
  final String id;
  final String assessmentId;
  final String userId;
  final ScreeningMovement movement;

  /// Pose frames extracted from the video clip (one per detected keyframe).
  final List<PoseFrame> frames;

  /// Compensation patterns detected by the AI analysis.
  final List<CompensationPattern> detectedCompensations;

  /// Path in Firebase Storage: users/{userId}/assessments/{assessmentId}/{movement}.mp4
  final String? storageVideoPath;

  final DateTime analyzedAt;

  const VideoAnalysis({
    required this.id,
    required this.assessmentId,
    required this.userId,
    required this.movement,
    required this.frames,
    required this.detectedCompensations,
    required this.analyzedAt,
    this.storageVideoPath,
  });

  /// True when at least one frame was successfully detected.
  bool get hasDetections => frames.isNotEmpty;

  /// Detection rate: proportion of processed frames with a detected pose.
  /// Returns 0.0 when [frames] is empty.
  double get detectionRate => frames.isEmpty ? 0.0 : 1.0;

  VideoAnalysis copyWith({
    String? id,
    String? assessmentId,
    String? userId,
    ScreeningMovement? movement,
    List<PoseFrame>? frames,
    List<CompensationPattern>? detectedCompensations,
    String? storageVideoPath,
    DateTime? analyzedAt,
  }) =>
      VideoAnalysis(
        id: id ?? this.id,
        assessmentId: assessmentId ?? this.assessmentId,
        userId: userId ?? this.userId,
        movement: movement ?? this.movement,
        frames: frames ?? this.frames,
        detectedCompensations:
            detectedCompensations ?? this.detectedCompensations,
        storageVideoPath: storageVideoPath ?? this.storageVideoPath,
        analyzedAt: analyzedAt ?? this.analyzedAt,
      );

  @override
  bool operator ==(Object other) =>
      other is VideoAnalysis && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
