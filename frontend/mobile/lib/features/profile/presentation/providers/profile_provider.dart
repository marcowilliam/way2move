import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';

// Watch current user's profile in real time
final profileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(userId);
});

// Profile notifier for actions
class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    final getProfile = GetProfile(ref.read(profileRepositoryProvider));
    final result = await getProfile(userId);
    return result.fold((_) => null, (profile) => profile);
  }

  Future<Either<AppFailure, UserProfile>> updateProfile(
      UserProfile profile) async {
    final useCase = UpdateProfile(ref.read(profileRepositoryProvider));
    final result = await useCase(profile);
    result.fold((_) {}, (updated) => state = AsyncData(updated));
    return result;
  }

  Future<Either<AppFailure, UserProfile>> completeOnboarding(
      UserProfile profile) async {
    final updated = profile.copyWith(onboardingComplete: true);
    return updateProfile(updated);
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

// Whether the current user has completed onboarding
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileStreamProvider).valueOrNull;
  return profile?.onboardingComplete ?? false;
});
