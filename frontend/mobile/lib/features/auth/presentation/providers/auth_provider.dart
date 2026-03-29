import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';

// Raw Firebase auth stream — used by the router for fast auth-gating
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Full AppUser stream
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// Auth notifier for actions (sign in / sign up / sign out)
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.watch(authRepositoryProvider).currentUser();
  }

  Future<Either<AppFailure, AppUser>> signIn(
      String email, String password) async {
    final useCase = SignIn(ref.read(authRepositoryProvider));
    final result = await useCase(email, password);
    result.fold((_) {}, (user) => state = AsyncData(user));
    return result;
  }

  Future<Either<AppFailure, AppUser>> signUp(
      String email, String password, String name) async {
    final useCase = SignUp(ref.read(authRepositoryProvider));
    final result = await useCase(email, password, name);
    result.fold((_) {}, (user) => state = AsyncData(user));
    return result;
  }

  Future<void> signOut() async {
    final useCase = SignOut(ref.read(authRepositoryProvider));
    await useCase();
    state = const AsyncData(null);
  }

  Future<Either<AppFailure, AppUser>> signInWithGoogle() async {
    final result =
        await ref.read(authRepositoryProvider).signInWithGoogle();
    result.fold((_) {}, (user) => state = AsyncData(user));
    return result;
  }

  Future<Either<AppFailure, AppUser>> signInWithApple() async {
    final result =
        await ref.read(authRepositoryProvider).signInWithApple();
    result.fold((_) {}, (user) => state = AsyncData(user));
    return result;
  }
}

// ignore: non_constant_identifier_names
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

// Convenience — current user ID (null if not signed in)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(firebaseAuthStateProvider).valueOrNull?.uid;
});
