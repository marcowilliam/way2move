import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';

class GetAssessmentHistory {
  final AssessmentRepository _repo;
  const GetAssessmentHistory(this._repo);

  Future<Either<AppFailure, List<Assessment>>> call(String userId) =>
      _repo.getAssessmentHistory(userId);
}
