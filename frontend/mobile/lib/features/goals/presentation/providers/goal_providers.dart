import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal.dart';
import '../../domain/usecases/create_goal.dart';
import '../../domain/usecases/get_goals.dart';
import '../../domain/usecases/get_goals_by_compensation.dart';
import '../../domain/usecases/get_suggested_goals.dart';
import '../../domain/usecases/mark_goal_achieved.dart';
import '../../domain/usecases/update_goal.dart';

// Use case providers
final createGoalUseCaseProvider = Provider<CreateGoal>(
    (ref) => CreateGoal(ref.watch(goalRepositoryProvider)));

final updateGoalUseCaseProvider = Provider<UpdateGoal>(
    (ref) => UpdateGoal(ref.watch(goalRepositoryProvider)));

final getGoalsUseCaseProvider =
    Provider<GetGoals>((ref) => GetGoals(ref.watch(goalRepositoryProvider)));

final getGoalsByCompensationUseCaseProvider = Provider<GetGoalsByCompensation>(
    (ref) => GetGoalsByCompensation(ref.watch(goalRepositoryProvider)));

final markGoalAchievedUseCaseProvider = Provider<MarkGoalAchieved>(
    (ref) => MarkGoalAchieved(ref.watch(goalRepositoryProvider)));

final getSuggestedGoalsUseCaseProvider =
    Provider<GetSuggestedGoals>((_) => const GetSuggestedGoals());

// All goals for the current user
final getGoalsProvider =
    FutureProvider.family<List<Goal>, String>((ref, userId) async {
  final result = await ref.watch(getGoalsUseCaseProvider).call(userId);
  return result.getRight().getOrElse(() => []);
});

// Active goals only
final activeGoalsProvider =
    FutureProvider.family<List<Goal>, String>((ref, userId) async {
  final result = await ref
      .watch(goalRepositoryProvider)
      .getByStatus(userId, GoalStatus.active);
  return result.getRight().getOrElse(() => []);
});

// Goal notifier for CRUD
class GoalNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return [];
    final result = await ref.watch(getGoalsUseCaseProvider).call(uid);
    return result.getRight().getOrElse(() => []);
  }

  Future<Either<AppFailure, Goal>> createGoal(Goal goal) async {
    final result = await ref.read(createGoalUseCaseProvider).call(goal);
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }

  Future<Either<AppFailure, Goal>> updateGoal(Goal goal) async {
    final result = await ref.read(updateGoalUseCaseProvider).call(goal);
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }

  Future<Either<AppFailure, Goal>> markAchieved(String goalId) async {
    final result = await ref.read(markGoalAchievedUseCaseProvider).call(goalId);
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }
}

final goalNotifierProvider =
    AsyncNotifierProvider<GoalNotifier, List<Goal>>(GoalNotifier.new);
