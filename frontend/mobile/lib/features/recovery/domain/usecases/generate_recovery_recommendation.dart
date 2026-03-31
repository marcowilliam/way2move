import '../entities/recovery_recommendation.dart';
import '../entities/recovery_score.dart';

class GenerateRecoveryRecommendation {
  const GenerateRecoveryRecommendation();

  RecoveryRecommendation call(RecoveryScore score) {
    return _forZone(score.zone);
  }

  static RecoveryRecommendation _forZone(RecoveryZone zone) {
    switch (zone) {
      case RecoveryZone.green:
        return const RecoveryRecommendation(
          zone: RecoveryZone.green,
          headline: "You're well-recovered. Train as planned.",
          detail:
              'Your body signals are strong — sleep, training load, and energy are all balanced. '
              'Today is a great day to push the intensity or add volume.',
          suggestedSessionType: SuggestedSessionType.trainAsPlanned,
        );
      case RecoveryZone.yellow:
        return const RecoveryRecommendation(
          zone: RecoveryZone.yellow,
          headline: 'Mild fatigue. Consider reducing volume by 20%.',
          detail:
              'Some fatigue signals detected. You can still train effectively — '
              'reduce your working sets by 20% or swap high-intensity work for mobility and technique focus.',
          suggestedSessionType: SuggestedSessionType.reducedVolume,
        );
      case RecoveryZone.red:
        return const RecoveryRecommendation(
          zone: RecoveryZone.red,
          headline: 'High fatigue. Rest or active recovery today.',
          detail:
              'Your body needs recovery time. Skip or significantly scale down your planned session. '
              'Light walking, gentle mobility work, or full rest will serve you best today.',
          suggestedSessionType: SuggestedSessionType.rest,
        );
    }
  }
}
