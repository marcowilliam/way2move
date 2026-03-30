import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/progression_rule.dart';
import '../repositories/progression_rule_repository.dart';

class GetProgressionRule {
  final ProgressionRuleRepository _repo;

  const GetProgressionRule(this._repo);

  /// If [exerciseId] is empty, returns the global rule.
  Future<Either<AppFailure, ProgressionRule>> call(String exerciseId) {
    if (exerciseId.isEmpty) {
      return _repo.getGlobalRule();
    }
    return _repo.getRule(exerciseId);
  }
}
