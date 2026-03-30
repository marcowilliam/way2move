import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/progress_photo.dart';
import '../repositories/progress_photo_repository.dart';

class GetPhotoTimeline {
  final ProgressPhotoRepository _repo;
  const GetPhotoTimeline(this._repo);

  Future<Either<AppFailure, List<ProgressPhoto>>> call(
    String userId, {
    int limit = 50,
  }) =>
      _repo.getTimeline(userId, limit: limit);
}
