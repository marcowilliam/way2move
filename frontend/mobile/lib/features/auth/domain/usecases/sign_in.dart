import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository _repo;
  const SignIn(this._repo);

  Future<Either<AppFailure, AppUser>> call(String email, String password) =>
      _repo.signIn(email, password);
}
