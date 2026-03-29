import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class GetSessionHistory {
  final SessionRepository _repo;
  const GetSessionHistory(this._repo);

  Future<Either<AppFailure, List<Session>>> call(String userId) =>
      _repo.getSessionHistory(userId);
}
