import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/re_assessment_schedule.dart';

abstract class ReAssessmentScheduleRepository {
  Future<Either<AppFailure, ReAssessmentSchedule?>> getSchedule(String userId);
  Future<Either<AppFailure, void>> updateInterval(
    String userId,
    int intervalWeeks,
  );
}
