import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../workouts/data/repositories/workout_repository_impl.dart';
import '../../data/repositories/protocol_repository_impl.dart';
import '../../domain/entities/protocol.dart';
import '../../domain/usecases/seed_ground_up_for_user.dart';

/// Live list of the user's currently-active protocols. Today screen pins
/// the workouts referenced by these protocols.
final activeProtocolsProvider = StreamProvider<List<Protocol>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  final repo = ref.watch(protocolRepositoryProvider);
  return repo.watchActiveProtocols(userId);
});

/// Use case provider for seeding the From-the-Ground-Up workout +
/// protocol. Idempotent — safe to call multiple times.
final seedGroundUpProvider = Provider<SeedGroundUpForUser>((ref) {
  return SeedGroundUpForUser(
    ref.watch(workoutRepositoryProvider),
    ref.watch(protocolRepositoryProvider),
  );
});
