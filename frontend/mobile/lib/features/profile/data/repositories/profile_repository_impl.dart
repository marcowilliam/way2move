import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/firestore_profile_datasource.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirestoreProfileDatasource _datasource;

  ProfileRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, UserProfile>> getProfile(String userId) async {
    try {
      final doc = await _datasource.getProfile(userId);
      if (!doc.exists) return const Left(NotFoundFailure());
      return Right(UserProfileModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, UserProfile>> updateProfile(
      UserProfile profile) async {
    try {
      final model = UserProfileModel.fromEntity(profile);
      await _datasource.updateProfile(profile.id, model.toFirestore());
      return Right(profile);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _datasource.watchProfile(userId).map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc).toEntity();
    });
  }
}

// Providers
final firestoreProfileDatasourceProvider =
    Provider<FirestoreProfileDatasource>((ref) {
  return FirestoreProfileDatasource(ref.watch(firestoreProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(firestoreProfileDatasourceProvider));
});
