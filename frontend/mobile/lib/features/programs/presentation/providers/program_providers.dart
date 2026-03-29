import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/program_repository_impl.dart';
import '../../domain/entities/program.dart';
import '../../domain/usecases/create_program.dart';
import '../../domain/usecases/deactivate_program.dart';
import '../../domain/usecases/get_active_program.dart';
import '../../domain/usecases/update_program.dart';

// ── Active program ────────────────────────────────────────────────────────────

class ActiveProgramNotifier extends AsyncNotifier<Program?> {
  @override
  Future<Program?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final result = await GetActiveProgram(
      ref.read(programRepositoryProvider),
    )(userId);
    return result.fold((_) => null, (p) => p);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final activeProgramProvider =
    AsyncNotifierProvider<ActiveProgramNotifier, Program?>(
  ActiveProgramNotifier.new,
);

// ── Create program ────────────────────────────────────────────────────────────

class CreateProgramNotifier extends AsyncNotifier<Program?> {
  @override
  Future<Program?> build() async => null;

  Future<Program?> submit(Program program) async {
    state = const AsyncLoading();
    final useCase = CreateProgram(ref.read(programRepositoryProvider));
    final result = await useCase(program);
    return result.fold(
      (_) {
        state = const AsyncData(null);
        return null;
      },
      (saved) {
        state = AsyncData(saved);
        ref.invalidate(activeProgramProvider);
        return saved;
      },
    );
  }
}

final createProgramProvider =
    AsyncNotifierProvider<CreateProgramNotifier, Program?>(
  CreateProgramNotifier.new,
);

// ── Update program ────────────────────────────────────────────────────────────

class UpdateProgramNotifier extends AsyncNotifier<Program?> {
  @override
  Future<Program?> build() async => null;

  Future<Program?> save(Program program) async {
    state = const AsyncLoading();
    final useCase = UpdateProgram(ref.read(programRepositoryProvider));
    final result = await useCase(program);
    return result.fold(
      (_) {
        state = const AsyncData(null);
        return null;
      },
      (updated) {
        state = AsyncData(updated);
        ref.invalidate(activeProgramProvider);
        return updated;
      },
    );
  }
}

final updateProgramProvider =
    AsyncNotifierProvider<UpdateProgramNotifier, Program?>(
  UpdateProgramNotifier.new,
);

// ── Deactivate program ────────────────────────────────────────────────────────

class DeactivateProgramNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> deactivate(String programId) async {
    state = const AsyncLoading();
    final useCase = DeactivateProgram(ref.read(programRepositoryProvider));
    final result = await useCase(programId);
    state = const AsyncData(null);
    if (result.isRight()) {
      ref.invalidate(activeProgramProvider);
      return true;
    }
    return false;
  }
}

final deactivateProgramProvider =
    AsyncNotifierProvider<DeactivateProgramNotifier, void>(
  DeactivateProgramNotifier.new,
);
