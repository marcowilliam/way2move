import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class CreateJournalEntry {
  final JournalRepository _repo;
  const CreateJournalEntry(this._repo);

  Future<Either<AppFailure, JournalEntry>> call(JournalEntry entry) =>
      _repo.create(entry);
}
