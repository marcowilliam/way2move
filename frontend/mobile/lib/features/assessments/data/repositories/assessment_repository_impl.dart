import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/assessment.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../datasources/firestore_assessment_datasource.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final FirestoreAssessmentDatasource _datasource;
  AssessmentRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, Assessment>> createAssessment(
      Assessment assessment) async {
    try {
      final model = await _datasource.create(assessment);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Assessment?>> getLatestAssessment(
      String userId) async {
    try {
      final model = await _datasource.getLatest(userId);
      return Right(model?.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Assessment>>> getAssessmentHistory(
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

  @override
  Future<Either<AppFailure, WeeklyPulse>> logWeeklyPulse(
      WeeklyPulse pulse) async {
    try {
      final model = await _datasource.logPulse(pulse);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, WeeklyPulse?>> getLatestWeeklyPulse(
      String userId) async {
    try {
      final model = await _datasource.getLatestPulse(userId);
      return Right(model?.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreAssessmentDatasourceProvider =
    Provider<FirestoreAssessmentDatasource>((ref) {
  return FirestoreAssessmentDatasource(ref.watch(firestoreProvider));
});

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepositoryImpl(
    ref.watch(firestoreAssessmentDatasourceProvider),
  );
});
