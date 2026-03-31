import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/firestore_recovery_score_datasource.dart';
import '../../data/repositories/recovery_score_repository_impl.dart';
import '../../domain/entities/recovery_recommendation.dart';
import '../../domain/entities/recovery_score.dart';
import '../../domain/repositories/recovery_score_repository.dart';
import '../../domain/usecases/generate_recovery_recommendation.dart';
import '../../domain/usecases/get_recovery_trend.dart';
import '../../domain/usecases/get_today_recovery_score.dart';

// ── DI ────────────────────────────────────────────────────────────────────────

final recoveryScoreDatasourceProvider =
    Provider<FirestoreRecoveryScoreDatasource>(
  (ref) => FirestoreRecoveryScoreDatasource(ref.watch(firestoreProvider)),
);

final recoveryScoreRepositoryProvider = Provider<RecoveryScoreRepository>(
  (ref) => RecoveryScoreRepositoryImpl(
    ref.watch(recoveryScoreDatasourceProvider),
  ),
);

final getTodayRecoveryScoreProvider = Provider<GetTodayRecoveryScore>(
  (ref) => GetTodayRecoveryScore(ref.watch(recoveryScoreRepositoryProvider)),
);

final getRecoveryTrendProvider = Provider<GetRecoveryTrend>(
  (ref) => GetRecoveryTrend(ref.watch(recoveryScoreRepositoryProvider)),
);

// ── Today's recovery score ────────────────────────────────────────────────────

class TodayRecoveryScoreNotifier extends AsyncNotifier<RecoveryScore?> {
  @override
  Future<RecoveryScore?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final result = await ref.read(getTodayRecoveryScoreProvider).call(userId);
    return result.fold((_) => null, (score) => score);
  }
}

final todayRecoveryScoreProvider =
    AsyncNotifierProvider<TodayRecoveryScoreNotifier, RecoveryScore?>(
  TodayRecoveryScoreNotifier.new,
);

// ── 7-day trend ───────────────────────────────────────────────────────────────

final recoveryTrendProvider = FutureProvider<List<RecoveryScore>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final result = await ref.read(getRecoveryTrendProvider).call(userId, 7);
  return result.fold((_) => [], (list) => list);
});

// ── Recommendation (derived) ──────────────────────────────────────────────────

const _generateRecommendation = GenerateRecoveryRecommendation();

final recoveryRecommendationProvider = Provider<RecoveryRecommendation?>((ref) {
  final scoreAsync = ref.watch(todayRecoveryScoreProvider);
  final score = scoreAsync.valueOrNull;
  if (score == null) return null;
  return _generateRecommendation(score);
});
