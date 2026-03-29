import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';

class LogWeeklyPulse {
  final AssessmentRepository _repo;
  const LogWeeklyPulse(this._repo);

  Future<Either<AppFailure, WeeklyPulse>> call(WeeklyPulse pulse) =>
      _repo.logWeeklyPulse(pulse);
}
