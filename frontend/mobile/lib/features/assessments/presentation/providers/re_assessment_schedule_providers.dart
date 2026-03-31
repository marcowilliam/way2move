import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/re_assessment_schedule_repository_impl.dart';
import '../../domain/entities/re_assessment_schedule.dart';
import '../../domain/usecases/get_re_assessment_schedule.dart';
import '../../domain/usecases/update_re_assessment_interval.dart';

// ── Schedule provider ─────────────────────────────────────────────────────────

class ReAssessmentScheduleNotifier
    extends AsyncNotifier<ReAssessmentSchedule?> {
  @override
  Future<ReAssessmentSchedule?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final result = await GetReAssessmentSchedule(
      ref.read(reAssessmentScheduleRepositoryProvider),
    )(userId);
    return result.fold((_) => null, (s) => s);
  }

  Future<bool> updateInterval(int intervalWeeks) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;
    final useCase = UpdateReAssessmentInterval(
      ref.read(reAssessmentScheduleRepositoryProvider),
    );
    final result = await useCase(userId, intervalWeeks);
    if (result.isRight()) {
      ref.invalidateSelf();
      await future;
    }
    return result.isRight();
  }
}

final reAssessmentScheduleProvider =
    AsyncNotifierProvider<ReAssessmentScheduleNotifier, ReAssessmentSchedule?>(
  ReAssessmentScheduleNotifier.new,
);
