import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/progression_suggestion.dart';
import '../services/progression_service.dart';

class EvaluateProgression {
  final ProgressionService _service;

  const EvaluateProgression(this._service);

  Either<AppFailure, List<ProgressionSuggestion>> call(ProgressionInput input) {
    try {
      final suggestions = _service.evaluate(input);
      return Right(suggestions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
