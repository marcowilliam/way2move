import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository _repo;
  const UpdateProfile(this._repo);

  Future<Either<AppFailure, UserProfile>> call(UserProfile profile) =>
      _repo.updateProfile(profile);
}
