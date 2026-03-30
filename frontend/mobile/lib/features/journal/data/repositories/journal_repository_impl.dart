import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/firestore_journal_datasource.dart';
import '../models/journal_entry_model.dart';

class JournalRepositoryImpl implements JournalRepository {
  final FirestoreJournalDatasource _datasource;

  JournalRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, JournalEntry>> create(JournalEntry entry) async {
    try {
      final model = JournalEntryModel.fromEntity(entry);
      final ref = await _datasource.create(model.toFirestore());
      final doc = await ref.get();
      return Right(JournalEntryModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<JournalEntry>>> getByDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final snap = await _datasource.getByDate(userId, date);
      final list = snap.docs
          .map((doc) => JournalEntryModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<JournalEntry>>> getByType(
    String userId,
    JournalType type, {
    int limit = 20,
  }) async {
    try {
      final snap = await _datasource.getByType(userId, type.name, limit: limit);
      final list = snap.docs
          .map((doc) => JournalEntryModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<JournalEntry>>> getForSession(
    String userId,
    String sessionId,
  ) async {
    try {
      final snap = await _datasource.getForSession(userId, sessionId);
      final list = snap.docs
          .map((doc) => JournalEntryModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<JournalEntry>>> getHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snap = await _datasource.getHistory(userId, limit: limit);
      final list = snap.docs
          .map((doc) => JournalEntryModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, void>> updateAutoCreatedEntities(
    String journalId,
    List<String> entityIds,
  ) async {
    try {
      await _datasource.updateAutoCreatedEntities(journalId, entityIds);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<JournalEntry>>> getByMonth(
    String userId,
    DateTime month,
  ) async {
    try {
      final snap = await _datasource.getByMonth(userId, month);
      final list = snap.docs
          .map((doc) => JournalEntryModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final firestoreJournalDatasourceProvider =
    Provider<FirestoreJournalDatasource>((ref) {
  return FirestoreJournalDatasource(ref.watch(firestoreProvider));
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepositoryImpl(ref.watch(firestoreJournalDatasourceProvider));
});
