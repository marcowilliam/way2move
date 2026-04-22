import '../../../assessments/domain/entities/assessment.dart';
import '../entities/goal.dart';

class GetSuggestedGoals {
  const GetSuggestedGoals();

  /// Returns a list of suggested Goal objects (origin: suggested, status: active)
  /// based on detected [compensationPatterns]. The goals have empty id/userId
  /// so callers must set those before persisting.
  List<Goal> call(List<CompensationPattern> compensationPatterns) {
    final suggestions = <Goal>[];
    for (final pattern in compensationPatterns) {
      final template = _templates[pattern];
      if (template != null) {
        suggestions.add(template);
      }
    }
    return suggestions;
  }

  static final Map<CompensationPattern, Goal> _templates = {
    CompensationPattern.forwardHeadPosture: const Goal(
      id: '',
      userId: '',
      name: 'Correct forward head posture',
      description: 'Improve cervical alignment through chin tuck exercises',
      category: GoalCategory.posture,
      targetMetric: 'chin tuck reps',
      targetValue: 15,
      unit: 'reps',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.roundedShoulders: const Goal(
      id: '',
      userId: '',
      name: 'Open thoracic spine',
      description: 'Improve thoracic mobility and shoulder positioning',
      category: GoalCategory.mobility,
      targetMetric: 'wall slide reps',
      targetValue: 20,
      unit: 'reps',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.anteriorPelvicTilt: const Goal(
      id: '',
      userId: '',
      name: 'Neutral pelvis control',
      description: 'Develop awareness and control of pelvic position',
      category: GoalCategory.stability,
      targetMetric: 'deadbug sets',
      targetValue: 3,
      unit: 'sets',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.poorCoreStability: const Goal(
      id: '',
      userId: '',
      name: 'Core endurance',
      description: 'Build anti-rotation and anti-extension core endurance',
      category: GoalCategory.stability,
      targetMetric: 'plank seconds',
      targetValue: 60,
      unit: 'seconds',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.weakGluteMed: const Goal(
      id: '',
      userId: '',
      name: 'Hip stability',
      description: 'Strengthen gluteus medius for frontal plane hip control',
      category: GoalCategory.strength,
      targetMetric: 'clamshell reps',
      targetValue: 20,
      unit: 'reps',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.limitedDorsiflexion: const Goal(
      id: '',
      userId: '',
      name: 'Ankle mobility',
      description: 'Restore adequate dorsiflexion range of motion',
      category: GoalCategory.mobility,
      targetMetric: 'dorsiflexion degrees',
      targetValue: 15,
      unit: 'degrees',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.thoracicKyphosis: const Goal(
      id: '',
      userId: '',
      name: 'Thoracic extension',
      description: 'Improve thoracic spine extension and rotation',
      category: GoalCategory.mobility,
      targetMetric: 'thoracic rotation reps',
      targetValue: 10,
      unit: 'reps',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.kneeValgus: const Goal(
      id: '',
      userId: '',
      name: 'Knee alignment',
      description: 'Improve neuromuscular control of knee in single-leg tasks',
      category: GoalCategory.stability,
      targetMetric: 'single leg squat reps',
      targetValue: 10,
      unit: 'reps',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.limitedHipInternalRotation: const Goal(
      id: '',
      userId: '',
      name: 'Hip internal rotation',
      description: 'Restore hip internal rotation range through 90/90 work',
      category: GoalCategory.mobility,
      targetMetric: 'hip 90/90 seconds',
      targetValue: 60,
      unit: 'seconds',
      origin: GoalOrigin.suggested,
    ),
    CompensationPattern.overPronation: const Goal(
      id: '',
      userId: '',
      name: 'Foot arch control',
      description: 'Improve intrinsic foot strength and single-leg balance',
      category: GoalCategory.stability,
      targetMetric: 'single leg balance seconds',
      targetValue: 30,
      unit: 'seconds',
      origin: GoalOrigin.suggested,
    ),
  };
}
