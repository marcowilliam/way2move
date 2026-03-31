import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/assessment.dart';

abstract class AssessmentRepository {
  Future<Either<AppFailure, Assessment>> createAssessment(
      Assessment assessment);
  Future<Either<AppFailure, Assessment?>> getLatestAssessment(String userId);
  Future<Either<AppFailure, List<Assessment>>> getAssessmentHistory(
      String userId);

  /// Returns a single assessment by its [id], or [NotFoundFailure] when absent.
  Future<Either<AppFailure, Assessment>> getAssessmentById(String id);

  Future<Either<AppFailure, WeeklyPulse>> logWeeklyPulse(WeeklyPulse pulse);
  Future<Either<AppFailure, WeeklyPulse?>> getLatestWeeklyPulse(String userId);
}
