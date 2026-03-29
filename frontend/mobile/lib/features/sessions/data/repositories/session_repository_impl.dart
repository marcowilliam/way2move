import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/firestore_session_datasource.dart';

class SessionRepositoryImpl implements SessionRepository {
  final FirestoreSessionDatasource _datasource;
  SessionRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, Session>> createSession(Session session) async {
    try {
      final model = await _datasource.create(session);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Session>> updateSession(Session session) async {
    try {
      final model = await _datasource.update(session);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<List<Session>> watchSessionsByDate(String userId, DateTime date) {
    return _datasource
        .watchByDate(userId, date)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Either<AppFailure, List<Session>>> getSessionHistory(
      String userId) async {
    try {
      final models = await _datasource.getHistory(userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreSessionDatasourceProvider =
    Provider<FirestoreSessionDatasource>((ref) {
  return FirestoreSessionDatasource(ref.watch(firestoreProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(
    ref.watch(firestoreSessionDatasourceProvider),
  );
});
