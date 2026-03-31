import 'recovery_score.dart';

enum SuggestedSessionType { trainAsPlanned, reducedVolume, mobilityOnly, rest }

class RecoveryRecommendation {
  final RecoveryZone zone;
  final String headline;
  final String detail;
  final SuggestedSessionType suggestedSessionType;

  const RecoveryRecommendation({
    required this.zone,
    required this.headline,
    required this.detail,
    required this.suggestedSessionType,
  });

  @override
  bool operator ==(Object other) =>
      other is RecoveryRecommendation &&
      other.zone == zone &&
      other.headline == headline;

  @override
  int get hashCode => Object.hash(zone, headline);
}
