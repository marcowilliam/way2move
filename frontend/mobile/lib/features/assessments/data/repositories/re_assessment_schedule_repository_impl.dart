import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/re_assessment_schedule.dart';
import '../../domain/repositories/re_assessment_schedule_repository.dart';
import '../datasources/firestore_re_assessment_schedule_datasource.dart';

class ReAssessmentScheduleRepositoryImpl
    implements ReAssessmentScheduleRepository {
  final FirestoreReAssessmentScheduleDatasource _datasource;

  ReAssessmentScheduleRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, ReAssessmentSchedule?>> getSchedule(
      String userId) async {
    try {
      final model = await _datasource.getSchedule(userId);
      return Right(model?.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, void>> updateInterval(
      String userId, int intervalWeeks) async {
    try {
      await _datasource.updateInterval(userId, intervalWeeks);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final firestoreReAssessmentScheduleDatasourceProvider =
    Provider<FirestoreReAssessmentScheduleDatasource>((ref) {
  return FirestoreReAssessmentScheduleDatasource(ref.watch(firestoreProvider));
});

final reAssessmentScheduleRepositoryProvider =
    Provider<ReAssessmentScheduleRepository>((ref) {
  return ReAssessmentScheduleRepositoryImpl(
    ref.watch(firestoreReAssessmentScheduleDatasourceProvider),
  );
});
