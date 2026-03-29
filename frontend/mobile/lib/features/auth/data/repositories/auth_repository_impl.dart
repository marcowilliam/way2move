import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _datasource;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(this._datasource, this._firestore);

  @override
  Stream<AppUser?> authStateChanges() {
    return _datasource.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _fetchUserDoc(firebaseUser.uid);
    });
  }

  @override
  Future<AppUser?> currentUser() async {
    final firebaseUser = _datasource.currentFirebaseUser;
    if (firebaseUser == null) return null;
    return _fetchUserDoc(firebaseUser.uid);
  }

  @override
  Future<Either<AppFailure, AppUser>> signIn(
      String email, String password) async {
    try {
      final credential = await _datasource.signInWithEmail(email, password);
      final user = await _fetchUserDoc(credential.user!.uid);
      return Right(user ?? _userFromCredential(credential));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, AppUser>> signUp(
      String email, String password, String name) async {
    try {
      final credential = await _datasource.signUpWithEmail(email, password);
      await _datasource.updateDisplayName(name);
      // onUserCreate Cloud Function creates the Firestore doc.
      // We return a local entity while the function runs.
      return Right(AppUser(
        id: credential.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      ));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, AppUser>> signInWithGoogle() async {
    try {
      final credential = await _datasource.signInWithGoogle();
      final user = await _fetchUserDoc(credential.user!.uid);
      return Right(user ?? _userFromCredential(credential));
    } on SignInCancelledException {
      return const Left(AuthFailure('sign-in-cancelled'));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, AppUser>> signInWithApple() async {
    try {
      final credential = await _datasource.signInWithApple();
      final user = await _fetchUserDoc(credential.user!.uid);
      return Right(user ?? _userFromCredential(credential));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('aborted')) {
        return const Left(AuthFailure('sign-in-cancelled'));
      }
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Unit>> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(unit);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  Future<AppUser?> _fetchUserDoc(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc).toEntity();
  }

  AppUser _userFromCredential(UserCredential credential) => AppUser(
        id: credential.user!.uid,
        email: credential.user!.email ?? '',
        name: credential.user!.displayName ?? '',
        avatarUrl: credential.user!.photoURL ?? '',
        createdAt: DateTime.now(),
      );
}

// Provider
final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource(
    ref.watch(firebaseAuthProvider),
    GoogleSignIn(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(firebaseAuthDatasourceProvider),
    ref.watch(firestoreProvider),
  );
});
