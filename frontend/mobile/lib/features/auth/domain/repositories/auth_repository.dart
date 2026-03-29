import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> currentUser();
  Future<Either<AppFailure, AppUser>> signIn(String email, String password);
  Future<Either<AppFailure, AppUser>> signUp(
      String email, String password, String name);
  Future<Either<AppFailure, AppUser>> signInWithGoogle();
  Future<Either<AppFailure, AppUser>> signInWithApple();
  Future<Either<AppFailure, Unit>> signOut();
}
