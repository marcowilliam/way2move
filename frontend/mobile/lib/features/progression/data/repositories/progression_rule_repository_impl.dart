import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/progression_rule.dart';
import '../../domain/repositories/progression_rule_repository.dart';
import '../datasources/firestore_progression_rule_datasource.dart';
import '../models/progression_rule_model.dart';

class ProgressionRuleRepositoryImpl implements ProgressionRuleRepository {
  final FirestoreProgressionRuleDatasource _datasource;
  final String _userId;

  ProgressionRuleRepositoryImpl(this._datasource, this._userId);

  @override
  Future<Either<AppFailure, ProgressionRule>> getRule(String exerciseId) async {
    try {
      final doc = await _datasource.getRule(_userId, exerciseId);
      if (!doc.exists) {
        // Fall back to global rule
        return getGlobalRule();
      }
      return Right(ProgressionRuleModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }

  @override
  Future<Either<AppFailure, ProgressionRule>> saveRule(
      ProgressionRule rule) async {
    try {
      final model = ProgressionRuleModel.fromEntity(rule);
      await _datasource.setRule(_userId, rule.exerciseId, model.toFirestore());
      return Right(rule);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }

  @override
  Future<Either<AppFailure, ProgressionRule>> getGlobalRule() async {
    try {
      final doc = await _datasource.getGlobalRule(_userId);
      if (!doc.exists) {
        return const Right(ProgressionRule()); // default rule
      }
      return Right(ProgressionRuleModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }

  @override
  Future<Either<AppFailure, ProgressionRule>> saveGlobalRule(
      ProgressionRule rule) async {
    try {
      final model = ProgressionRuleModel.fromEntity(rule);
      await _datasource.setGlobalRule(_userId, model.toFirestore());
      return Right(rule);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }
}

final progressionRuleRepositoryProvider =
    Provider<ProgressionRuleRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider) ?? '';
  final db = ref.watch(firestoreProvider);
  final datasource = FirestoreProgressionRuleDatasource(db);
  return ProgressionRuleRepositoryImpl(datasource, userId);
});
