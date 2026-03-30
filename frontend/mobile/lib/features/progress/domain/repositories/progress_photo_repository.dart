import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/progress_photo.dart';

abstract class ProgressPhotoRepository {
  Future<Either<AppFailure, ProgressPhoto>> capturePhoto(ProgressPhoto photo);

  Future<Either<AppFailure, List<ProgressPhoto>>> getPhotosByDate(
    String userId,
    DateTime date,
  );

  Future<Either<AppFailure, List<ProgressPhoto>>> getTimeline(
    String userId, {
    int limit = 50,
  });

  Future<Either<AppFailure, List<ProgressPhoto>>> getByAngle(
    String userId,
    PhotoAngle angle,
  );
}
