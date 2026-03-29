import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';

class CreateAssessment {
  final AssessmentRepository _repo;
  const CreateAssessment(this._repo);

  Future<Either<AppFailure, Assessment>> call(Assessment assessment) =>
      _repo.createAssessment(assessment);
}
