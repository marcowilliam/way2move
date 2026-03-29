import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';

class GetLatestAssessment {
  final AssessmentRepository _repo;
  const GetLatestAssessment(this._repo);

  Future<Either<AppFailure, Assessment?>> call(String userId) =>
      _repo.getLatestAssessment(userId);
}
