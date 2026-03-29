import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/compensation_repository_impl.dart';
import '../../domain/entities/compensation.dart';
import '../../domain/usecases/create_compensation.dart';
import '../../domain/usecases/get_active_compensations.dart';
import '../../domain/usecases/mark_compensation_improving.dart';
import '../../domain/usecases/mark_compensation_resolved.dart';
import '../../domain/usecases/update_compensation.dart';

// Use case providers
final createCompensationProvider = Provider<CreateCompensation>(
    (ref) => CreateCompensation(ref.watch(compensationRepositoryProvider)));

final updateCompensationUseCaseProvider = Provider<UpdateCompensation>(
    (ref) => UpdateCompensation(ref.watch(compensationRepositoryProvider)));

final getActiveCompensationsProvider = Provider<GetActiveCompensations>(
    (ref) => GetActiveCompensations(ref.watch(compensationRepositoryProvider)));

final markCompensationImprovingProvider = Provider<MarkCompensationImproving>(
    (ref) =>
        MarkCompensationImproving(ref.watch(compensationRepositoryProvider)));

final markCompensationResolvedProvider = Provider<MarkCompensationResolved>(
    (ref) =>
        MarkCompensationResolved(ref.watch(compensationRepositoryProvider)));

// Stream of all user compensations (active + improving + resolved)
final compensationStreamProvider = StreamProvider<List<Compensation>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(compensationRepositoryProvider).watchByUser(uid);
});

// Only active + improving compensations
final activeCompensationsProvider =
    FutureProvider<List<Compensation>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];
  final result = await ref.watch(getActiveCompensationsProvider).call(uid);
  return result.getRight().getOrElse(() => []);
});

// State notifier for compensation CRUD operations
class CompensationNotifier extends AsyncNotifier<List<Compensation>> {
  @override
  Future<List<Compensation>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return [];
    final result = await ref.watch(getActiveCompensationsProvider).call(uid);
    return result.getRight().getOrElse(() => []);
  }

  Future<Either<AppFailure, Compensation>> createCompensation(
      Compensation compensation) async {
    final result =
        await ref.read(createCompensationProvider).call(compensation);
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }

  Future<Either<AppFailure, Compensation>> updateCompensation(
      Compensation compensation) async {
    final result =
        await ref.read(updateCompensationUseCaseProvider).call(compensation);
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }

  Future<Either<AppFailure, Compensation>> markImproving(
      String compensationId, String note) async {
    final result = await ref
        .read(markCompensationImprovingProvider)
        .call(compensationId, note);
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }

  Future<Either<AppFailure, Compensation>> markResolved(
      String compensationId, String note) async {
    final result = await ref
        .read(markCompensationResolvedProvider)
        .call(compensationId, note);
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }
}

final compensationNotifierProvider =
    AsyncNotifierProvider<CompensationNotifier, List<Compensation>>(
        CompensationNotifier.new);
