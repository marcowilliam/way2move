import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class GetJournalsForSession {
  final JournalRepository _repo;
  const GetJournalsForSession(this._repo);

  Future<Either<AppFailure, List<JournalEntry>>> call(
    String userId,
    String sessionId,
  ) =>
      _repo.getForSession(userId, sessionId);
}
