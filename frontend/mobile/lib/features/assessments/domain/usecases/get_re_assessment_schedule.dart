import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/re_assessment_schedule.dart';
import '../repositories/re_assessment_schedule_repository.dart';

class GetReAssessmentSchedule {
  final ReAssessmentScheduleRepository _repo;
  const GetReAssessmentSchedule(this._repo);

  Future<Either<AppFailure, ReAssessmentSchedule?>> call(String userId) =>
      _repo.getSchedule(userId);
}
