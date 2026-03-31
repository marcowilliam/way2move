import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/re_assessment_schedule.dart';
import '../repositories/re_assessment_schedule_repository.dart';

class UpdateReAssessmentInterval {
  final ReAssessmentScheduleRepository _repo;
  const UpdateReAssessmentInterval(this._repo);

  /// [intervalWeeks] must be one of [kAssessmentIntervalOptions].
  Future<Either<AppFailure, void>> call(String userId, int intervalWeeks) {
    if (!kAssessmentIntervalOptions.contains(intervalWeeks)) {
      return Future.value(
        const Left(ValidationFailure('intervalWeeks must be 4, 6, 8, or 12')),
      );
    }
    return _repo.updateInterval(userId, intervalWeeks);
  }
}
