import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/protocol.dart';
import '../../domain/repositories/protocol_repository.dart';
import '../datasources/firestore_protocol_datasource.dart';

class ProtocolRepositoryImpl implements ProtocolRepository {
  final FirestoreProtocolDatasource _datasource;
  ProtocolRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, List<Protocol>>> getActiveProtocols(
      String userId) async {
    try {
      final models = await _datasource.getActiveProtocols(userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<List<Protocol>> watchActiveProtocols(String userId) {
    return _datasource
        .watchActiveProtocols(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Either<AppFailure, Protocol>> getProtocolById(
      String protocolId) async {
    try {
      final model = await _datasource.getProtocolById(protocolId);
      if (model == null) return const Left(NotFoundFailure());
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Protocol>> createProtocol(Protocol protocol) async {
    try {
      final model = await _datasource.create(protocol);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Protocol>> updateProtocol(Protocol protocol) async {
    try {
      final model = await _datasource.update(protocol);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Protocol>> completeProtocol(
      String protocolId) async {
    try {
      await _datasource.markCompleted(protocolId);
      final model = await _datasource.getProtocolById(protocolId);
      if (model == null) return const Left(NotFoundFailure());
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

final firestoreProtocolDatasourceProvider =
    Provider<FirestoreProtocolDatasource>((ref) {
  return FirestoreProtocolDatasource(ref.watch(firestoreProvider));
});

final protocolRepositoryProvider = Provider<ProtocolRepository>((ref) {
  return ProtocolRepositoryImpl(
    ref.watch(firestoreProtocolDatasourceProvider),
  );
});
