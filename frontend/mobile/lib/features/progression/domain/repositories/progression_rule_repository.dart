import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/progression_rule.dart';

abstract class ProgressionRuleRepository {
  /// Returns the exercise-specific rule, or the global rule if none exists.
  Future<Either<AppFailure, ProgressionRule>> getRule(String exerciseId);

  Future<Either<AppFailure, ProgressionRule>> saveRule(ProgressionRule rule);

  Future<Either<AppFailure, ProgressionRule>> getGlobalRule();

  Future<Either<AppFailure, ProgressionRule>> saveGlobalRule(
      ProgressionRule rule);
}
