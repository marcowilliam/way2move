import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/progression_rule.dart';
import '../repositories/progression_rule_repository.dart';

class SaveProgressionRule {
  final ProgressionRuleRepository _repo;

  const SaveProgressionRule(this._repo);

  Future<Either<AppFailure, ProgressionRule>> call(ProgressionRule rule) {
    if (rule.isGlobal) {
      return _repo.saveGlobalRule(rule);
    }
    return _repo.saveRule(rule);
  }
}
