import '../entities/assessment.dart';

/// Rule-based compensation detection from questionnaire answers.
///
/// Answer keys:
///   occupation      — 'desk' | 'active' | 'mixed'
///   sittingHours    — 'lt2'  | '2to4'  | '4to6' | 'gt6'
///   neckPain        — bool
///   lowerBackPain   — bool
///   kneePain        — bool
///   isRunner        — bool
///   anklePain       — bool
///   shoulderPainOverhead — bool
abstract class CompensationDetectionService {
  static List<CompensationPattern> detectCompensations(
      Map<String, dynamic> answers) {
    final Set<CompensationPattern> found = {};

    final bool isDeskJob = answers['occupation'] == 'desk';
    final bool sittingGt6 = answers['sittingHours'] == 'gt6';
    final bool sittingGt4 = answers['sittingHours'] == '4to6' || sittingGt6;
    final bool neckPain = answers['neckPain'] == true;
    final bool lowerBackPain = answers['lowerBackPain'] == true;
    final bool kneePain = answers['kneePain'] == true;
    final bool isRunner = answers['isRunner'] == true;
    final bool anklePain = answers['anklePain'] == true;
    final bool shoulderOverhead = answers['shoulderPainOverhead'] == true;

    if (isDeskJob && neckPain) {
      found.addAll([
        CompensationPattern.forwardHeadPosture,
        CompensationPattern.roundedShoulders,
      ]);
    }
    if (sittingGt6) {
      found.addAll([
        CompensationPattern.anteriorPelvicTilt,
        CompensationPattern.poorCoreStability,
      ]);
    }
    if (lowerBackPain && (isDeskJob || sittingGt4)) {
      found.addAll([
        CompensationPattern.anteriorPelvicTilt,
        CompensationPattern.excessiveLumbarLordosis,
      ]);
    }
    if (kneePain && isRunner) {
      found.addAll([
        CompensationPattern.kneeValgus,
        CompensationPattern.weakGluteMed,
      ]);
    }
    if (anklePain) {
      found.addAll([
        CompensationPattern.limitedDorsiflexion,
        CompensationPattern.overPronation,
      ]);
    }
    if (shoulderOverhead) {
      found.addAll([
        CompensationPattern.roundedShoulders,
        CompensationPattern.limitedThoracicRotation,
      ]);
    }

    return found.toList();
  }

  /// Score drops with each compensation found: 10 → 4.
  static double calculateOverallScore(List<CompensationPattern> patterns) {
    if (patterns.isEmpty) return 10.0;
    if (patterns.length <= 2) return 8.0;
    if (patterns.length <= 4) return 6.0;
    return 4.0;
  }

  /// Human-readable label for each compensation pattern.
  static String labelFor(CompensationPattern pattern) {
    switch (pattern) {
      case CompensationPattern.forwardHeadPosture:
        return 'Forward Head Posture';
      case CompensationPattern.roundedShoulders:
        return 'Rounded Shoulders';
      case CompensationPattern.anteriorPelvicTilt:
        return 'Anterior Pelvic Tilt';
      case CompensationPattern.posteriorPelvicTilt:
        return 'Posterior Pelvic Tilt';
      case CompensationPattern.excessiveLumbarLordosis:
        return 'Excessive Lumbar Lordosis';
      case CompensationPattern.thoracicKyphosis:
        return 'Thoracic Kyphosis';
      case CompensationPattern.kneeValgus:
        return 'Knee Valgus (Knock-Knees)';
      case CompensationPattern.overPronation:
        return 'Over-Pronation';
      case CompensationPattern.limitedDorsiflexion:
        return 'Limited Ankle Dorsiflexion';
      case CompensationPattern.limitedHipInternalRotation:
        return 'Limited Hip Internal Rotation';
      case CompensationPattern.limitedHipExternalRotation:
        return 'Limited Hip External Rotation';
      case CompensationPattern.limitedThoracicRotation:
        return 'Limited Thoracic Rotation';
      case CompensationPattern.weakGluteMed:
        return 'Weak Glute Medius';
      case CompensationPattern.poorCoreStability:
        return 'Poor Core Stability';
    }
  }
}
