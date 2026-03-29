import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUp {
  final AuthRepository _repo;
  const SignUp(this._repo);

  Future<Either<AppFailure, AppUser>> call(
          String email, String password, String name) =>
      _repo.signUp(email, password, name);
}
