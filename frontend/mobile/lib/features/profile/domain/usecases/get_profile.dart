import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository _repo;
  const GetProfile(this._repo);

  Future<Either<AppFailure, UserProfile>> call(String userId) =>
      _repo.getProfile(userId);
}
