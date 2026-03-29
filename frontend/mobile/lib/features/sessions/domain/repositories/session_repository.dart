import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/session.dart';

abstract class SessionRepository {
  Future<Either<AppFailure, Session>> createSession(Session session);
  Future<Either<AppFailure, Session>> updateSession(Session session);
  Stream<List<Session>> watchSessionsByDate(String userId, DateTime date);
  Future<Either<AppFailure, List<Session>>> getSessionHistory(String userId);
}
