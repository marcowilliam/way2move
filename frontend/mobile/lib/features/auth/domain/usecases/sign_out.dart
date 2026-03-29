import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository _repo;
  const SignOut(this._repo);

  Future<Either<AppFailure, Unit>> call() => _repo.signOut();
}
