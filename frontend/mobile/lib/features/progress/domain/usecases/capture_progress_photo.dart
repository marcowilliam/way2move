import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/progress_photo.dart';
import '../repositories/progress_photo_repository.dart';

class CaptureProgressPhoto {
  final ProgressPhotoRepository _repo;
  const CaptureProgressPhoto(this._repo);

  Future<Either<AppFailure, ProgressPhoto>> call(ProgressPhoto photo) =>
      _repo.capturePhoto(photo);
}
