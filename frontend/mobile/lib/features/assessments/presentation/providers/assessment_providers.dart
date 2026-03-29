import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/assessment_repository_impl.dart';
import '../../domain/entities/assessment.dart';
import '../../domain/usecases/create_assessment.dart';
import '../../domain/usecases/get_assessment_history.dart';
import '../../domain/usecases/get_latest_assessment.dart';
import '../../domain/usecases/get_latest_weekly_pulse.dart';
import '../../domain/usecases/log_weekly_pulse.dart';

// ── Latest assessment ────────────────────────────────────────────────────────

class LatestAssessmentNotifier extends AsyncNotifier<Assessment?> {
  @override
  Future<Assessment?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final result = await GetLatestAssessment(
      ref.read(assessmentRepositoryProvider),
    )(userId);
    return result.fold((_) => null, (a) => a);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final latestAssessmentProvider =
    AsyncNotifierProvider<LatestAssessmentNotifier, Assessment?>(
  LatestAssessmentNotifier.new,
);

// ── Assessment history ───────────────────────────────────────────────────────

final assessmentHistoryProvider = FutureProvider<List<Assessment>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final result = await GetAssessmentHistory(
    ref.watch(assessmentRepositoryProvider),
  )(userId);
  return result.fold((_) => [], (list) => list);
});

// ── Create assessment ────────────────────────────────────────────────────────

class CreateAssessmentNotifier extends AsyncNotifier<Assessment?> {
  @override
  Future<Assessment?> build() async => null;

  Future<Assessment?> submit(Assessment assessment) async {
    state = const AsyncLoading();
    final useCase = CreateAssessment(ref.read(assessmentRepositoryProvider));
    final result = await useCase(assessment);
    return result.fold(
      (_) {
        state = const AsyncData(null);
        return null;
      },
      (saved) {
        state = AsyncData(saved);
        ref.invalidate(latestAssessmentProvider);
        ref.invalidate(assessmentHistoryProvider);
        return saved;
      },
    );
  }
}

final createAssessmentProvider =
    AsyncNotifierProvider<CreateAssessmentNotifier, Assessment?>(
  CreateAssessmentNotifier.new,
);

// ── Weekly pulse ─────────────────────────────────────────────────────────────

class WeeklyPulseNotifier extends AsyncNotifier<WeeklyPulse?> {
  @override
  Future<WeeklyPulse?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final result = await GetLatestWeeklyPulse(
      ref.read(assessmentRepositoryProvider),
    )(userId);
    return result.fold((_) => null, (p) => p);
  }

  Future<bool> log(WeeklyPulse pulse) async {
    final useCase = LogWeeklyPulse(ref.read(assessmentRepositoryProvider));
    final result = await useCase(pulse);
    if (result.isRight()) {
      state = AsyncData(result.getRight().toNullable());
    }
    return result.isRight();
  }
}

final weeklyPulseProvider =
    AsyncNotifierProvider<WeeklyPulseNotifier, WeeklyPulse?>(
  WeeklyPulseNotifier.new,
);
