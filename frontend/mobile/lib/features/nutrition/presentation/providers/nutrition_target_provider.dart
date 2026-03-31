import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/repositories/nutrition_target_repository_impl.dart';
import '../../domain/entities/nutrition_target.dart';
import '../../domain/usecases/calculate_nutrition_target.dart';
import '../../domain/usecases/get_nutrition_target.dart';
import '../../domain/usecases/save_nutrition_target.dart';

// ── Use-case providers ────────────────────────────────────────────────────────

final _getNutritionTargetProvider = Provider<GetNutritionTarget>((ref) {
  return GetNutritionTarget(ref.watch(nutritionTargetRepositoryProvider));
});

final _saveNutritionTargetProvider = Provider<SaveNutritionTarget>((ref) {
  return SaveNutritionTarget(ref.watch(nutritionTargetRepositoryProvider));
});

final _calculateNutritionTargetProvider =
    Provider<CalculateNutritionTarget>((ref) {
  return const CalculateNutritionTarget();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class NutritionTargetNotifier extends AsyncNotifier<NutritionTarget?> {
  @override
  Future<NutritionTarget?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final result = await ref.read(_getNutritionTargetProvider).call(userId);
    return result.fold((_) => null, (target) => target);
  }

  /// Recalculates target from profile + selected preset and saves it.
  Future<bool> applyPreset(MacroPreset preset) async {
    final profile = ref.read(profileStreamProvider).valueOrNull;
    if (profile == null) return false;

    final calculated = ref
        .read(_calculateNutritionTargetProvider)
        .call(profile: profile, preset: preset);
    if (calculated == null) return false;

    final result =
        await ref.read(_saveNutritionTargetProvider).call(calculated);
    result.fold((_) {}, (saved) => state = AsyncData(saved));
    return result.isRight();
  }

  /// Saves a manually edited target without recalculating from profile.
  Future<bool> saveTarget(NutritionTarget target) async {
    final result = await ref.read(_saveNutritionTargetProvider).call(target);
    result.fold((_) {}, (saved) => state = AsyncData(saved));
    return result.isRight();
  }
}

final nutritionTargetNotifierProvider =
    AsyncNotifierProvider<NutritionTargetNotifier, NutritionTarget?>(
  NutritionTargetNotifier.new,
);
