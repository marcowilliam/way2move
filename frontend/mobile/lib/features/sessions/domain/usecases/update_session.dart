import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class UpdateSession {
  final SessionRepository _repo;
  const UpdateSession(this._repo);

  Future<Either<AppFailure, Session>> call(Session session) =>
      _repo.updateSession(session);
}
