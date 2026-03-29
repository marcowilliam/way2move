import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<AppFailure, UserProfile>> getProfile(String userId);
  Future<Either<AppFailure, UserProfile>> updateProfile(UserProfile profile);
  Stream<UserProfile?> watchProfile(String userId);
}
