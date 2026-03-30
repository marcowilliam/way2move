import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/progression_rule_repository_impl.dart';
import '../../domain/entities/progression_rule.dart';
import '../../domain/entities/progression_suggestion.dart';
import '../../domain/services/progression_service.dart';
import '../../domain/usecases/evaluate_progression.dart';
import '../../domain/usecases/get_progression_rule.dart';
import '../../domain/usecases/save_progression_rule.dart';

// Service provider — pure domain, no deps
final progressionServiceProvider = Provider<ProgressionService>(
  (_) => const ProgressionService(),
);

// Use case providers
final evaluateProgressionProvider = Provider<EvaluateProgression>(
  (ref) => EvaluateProgression(ref.watch(progressionServiceProvider)),
);

final saveProgressionRuleUseCaseProvider = Provider<SaveProgressionRule>(
  (ref) => SaveProgressionRule(ref.watch(progressionRuleRepositoryProvider)),
);

final getProgressionRuleUseCaseProvider = Provider<GetProgressionRule>(
  (ref) => GetProgressionRule(ref.watch(progressionRuleRepositoryProvider)),
);

// Global rule notifier
class GlobalProgressionRuleNotifier extends AsyncNotifier<ProgressionRule> {
  @override
  Future<ProgressionRule> build() async {
    final result = await ref.watch(getProgressionRuleUseCaseProvider).call('');
    return result.getRight().getOrElse(() => const ProgressionRule());
  }

  Future<Either<AppFailure, ProgressionRule>> save(ProgressionRule rule) async {
    final result =
        await ref.read(saveProgressionRuleUseCaseProvider).call(rule);
    if (result.isRight()) {
      state = AsyncData(result.getRight().getOrElse(() => rule));
    }
    return result;
  }
}

final globalProgressionRuleNotifierProvider =
    AsyncNotifierProvider<GlobalProgressionRuleNotifier, ProgressionRule>(
  GlobalProgressionRuleNotifier.new,
);

// Pending suggestions populated after session completion
final pendingSuggestionsProvider =
    StateProvider<List<ProgressionSuggestion>>((_) => const []);
