import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class GetJournalsByDate {
  final JournalRepository _repo;
  const GetJournalsByDate(this._repo);

  Future<Either<AppFailure, List<JournalEntry>>> call(
    String userId,
    DateTime date,
  ) =>
      _repo.getByDate(userId, date);
}
