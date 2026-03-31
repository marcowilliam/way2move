import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/recovery/domain/entities/recovery_recommendation.dart';
import 'package:way2move/features/recovery/domain/entities/recovery_score.dart';
import 'package:way2move/features/recovery/domain/usecases/generate_recovery_recommendation.dart';

RecoveryScore _scoreWith(double score) => RecoveryScore(
      id: 'id',
      userId: 'u1',
      date: DateTime.now(),
      score: score,
      components: const RecoveryScoreComponents(
        sleepComponent: 50,
        trainingLoadComponent: 50,
        weeklyPulseComponent: 50,
        gutFeelingComponent: 50,
      ),
      recommendation: '',
    );

void main() {
  const usecase = GenerateRecoveryRecommendation();

  group('GenerateRecoveryRecommendation', () {
    test('score 100 returns green zone', () {
      final rec = usecase(_scoreWith(100));
      expect(rec.zone, RecoveryZone.green);
      expect(rec.suggestedSessionType, SuggestedSessionType.trainAsPlanned);
    });

    test('score 75 returns green zone (boundary)', () {
      final rec = usecase(_scoreWith(75));
      expect(rec.zone, RecoveryZone.green);
    });

    test('score 74 returns yellow zone (boundary)', () {
      final rec = usecase(_scoreWith(74));
      expect(rec.zone, RecoveryZone.yellow);
      expect(rec.suggestedSessionType, SuggestedSessionType.reducedVolume);
    });

    test('score 50 returns yellow zone (boundary)', () {
      final rec = usecase(_scoreWith(50));
      expect(rec.zone, RecoveryZone.yellow);
    });

    test('score 49 returns red zone (boundary)', () {
      final rec = usecase(_scoreWith(49));
      expect(rec.zone, RecoveryZone.red);
      expect(rec.suggestedSessionType, SuggestedSessionType.rest);
    });

    test('score 0 returns red zone', () {
      final rec = usecase(_scoreWith(0));
      expect(rec.zone, RecoveryZone.red);
    });

    test('recommendation has non-empty headline and detail', () {
      for (final score in [0.0, 50.0, 75.0, 100.0]) {
        final rec = usecase(_scoreWith(score));
        expect(rec.headline, isNotEmpty);
        expect(rec.detail, isNotEmpty);
      }
    });
  });
}
