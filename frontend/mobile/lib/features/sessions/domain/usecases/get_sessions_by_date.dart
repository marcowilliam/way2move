import '../entities/session.dart';
import '../repositories/session_repository.dart';

class GetSessionsByDate {
  final SessionRepository _repo;
  const GetSessionsByDate(this._repo);

  Stream<List<Session>> call(String userId, DateTime date) =>
      _repo.watchSessionsByDate(userId, date);
}
