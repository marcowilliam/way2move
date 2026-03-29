import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/compensation.dart';
import '../../domain/repositories/compensation_repository.dart';
import '../datasources/firestore_compensation_datasource.dart';
import '../models/compensation_model.dart';

class CompensationRepositoryImpl implements CompensationRepository {
  final FirestoreCompensationDatasource _datasource;

  CompensationRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, Compensation>> create(
      Compensation compensation) async {
    try {
      final model = CompensationModel.fromEntity(compensation);
      final data = model.toFirestore();
      data['meta'] = {
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final ref = await _datasource.create(compensation.userId, data);
      final doc = await ref.get();
      return Right(CompensationModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Compensation>> update(
      Compensation compensation) async {
    try {
      final model = CompensationModel.fromEntity(compensation);
      await _datasource.update(compensation.id, model.toFirestore());
      final doc = await _datasource.get(compensation.id);
      if (!doc.exists) return const Left(NotFoundFailure());
      return Right(CompensationModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Compensation>>> getActive(
      String userId) async {
    try {
      final snap = await _datasource.getActive(userId);
      final list = snap.docs
          .map((doc) => CompensationModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Compensation>>> getByRegion(
      String userId, CompensationRegion region) async {
    try {
      final snap = await _datasource.getByRegion(userId, region.name);
      final list = snap.docs
          .map((doc) => CompensationModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<List<Compensation>> watchByUser(String userId) {
    return _datasource.watchByUser(userId).map((snap) => snap.docs
        .map((doc) => CompensationModel.fromFirestore(doc).toEntity())
        .toList());
  }

  @override
  Future<Either<AppFailure, Compensation>> markImproving(
      String compensationId, String note) async {
    try {
      final doc = await _datasource.get(compensationId);
      if (!doc.exists) return const Left(NotFoundFailure());
      final current = CompensationModel.fromFirestore(doc).toEntity();

      final historyEntry = CompensationHistoryEntry(
        date: DateTime.now(),
        severity: current.severity,
        status: CompensationStatus.improving,
        note: note,
      );
      final updated = current.copyWith(
        status: CompensationStatus.improving,
        history: [...current.history, historyEntry],
      );
      return update(updated);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Compensation>> markResolved(
      String compensationId, String note) async {
    try {
      final doc = await _datasource.get(compensationId);
      if (!doc.exists) return const Left(NotFoundFailure());
      final current = CompensationModel.fromFirestore(doc).toEntity();

      final now = DateTime.now();
      final historyEntry = CompensationHistoryEntry(
        date: now,
        severity: current.severity,
        status: CompensationStatus.resolved,
        note: note,
      );
      final updated = current.copyWith(
        status: CompensationStatus.resolved,
        resolvedAt: now,
        history: [...current.history, historyEntry],
      );
      return update(updated);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreCompensationDatasourceProvider =
    Provider<FirestoreCompensationDatasource>((ref) {
  return FirestoreCompensationDatasource(ref.watch(firestoreProvider));
});

final compensationRepositoryProvider = Provider<CompensationRepository>((ref) {
  return CompensationRepositoryImpl(
      ref.watch(firestoreCompensationDatasourceProvider));
});
