import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/video_analysis.dart';
import '../models/video_analysis_model.dart';

class FirestoreVideoAnalysisDatasource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  FirestoreVideoAnalysisDatasource(this._db, this._storage);

  Future<VideoAnalysisModel> save(VideoAnalysis analysis) async {
    final docRef = _db.collection('videoAnalyses').doc();
    final model = VideoAnalysisModel.fromEntity(
      analysis.copyWith(id: docRef.id),
    );
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<List<VideoAnalysisModel>> getByAssessment(String assessmentId) async {
    final snap = await _db
        .collection('videoAnalyses')
        .where('assessmentId', isEqualTo: assessmentId)
        .orderBy('analyzedAt')
        .get();
    return snap.docs.map(VideoAnalysisModel.fromFirestore).toList();
  }

  /// Uploads [localFile] to Firebase Storage and returns the storage path.
  ///
  /// Storage path: `users/{userId}/assessments/{assessmentId}/{movementName}.mp4`
  Future<String> uploadVideo({
    required File localFile,
    required String userId,
    required String assessmentId,
    required String movementName,
    void Function(double progress)? onProgress,
  }) async {
    final storagePath =
        'users/$userId/assessments/$assessmentId/$movementName.mp4';
    final ref = _storage.ref(storagePath);

    final uploadTask = ref.putFile(
      localFile,
      SettableMetadata(contentType: 'video/mp4'),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    await uploadTask;
    return storagePath;
  }
}
