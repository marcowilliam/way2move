import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/journal_entry.dart';

abstract class JournalRepository {
  Future<Either<AppFailure, JournalEntry>> create(JournalEntry entry);

  Future<Either<AppFailure, List<JournalEntry>>> getByDate(
    String userId,
    DateTime date,
  );

  Future<Either<AppFailure, List<JournalEntry>>> getByType(
    String userId,
    JournalType type, {
    int limit = 20,
  });

  Future<Either<AppFailure, List<JournalEntry>>> getForSession(
    String userId,
    String sessionId,
  );

  Future<Either<AppFailure, List<JournalEntry>>> getHistory(
    String userId, {
    int limit = 50,
  });
}
