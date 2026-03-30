import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/progress_photo.dart';
import '../models/progress_photo_model.dart';

class FirestoreProgressPhotoDatasource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  FirestoreProgressPhotoDatasource(this._db, this._storage);

  /// Uploads [imageFile] to Storage and creates a Firestore document.
  /// Returns the saved model with the download URL as [photoUrl].
  Future<ProgressPhotoModel> uploadAndSave({
    required File imageFile,
    required String userId,
    required DateTime date,
    required PhotoAngle angle,
    String? notes,
  }) async {
    final dateStr = DateFormat('yyyyMMdd').format(date);
    final path = 'users/$userId/progress/${dateStr}_${angle.name}.jpg';
    final ref = _storage.ref(path);
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    final docRef = _db.collection('progressPhotos').doc();
    final model = ProgressPhotoModel(
      id: docRef.id,
      userId: userId,
      date: date,
      photoUrl: url,
      angle: angle.name,
      notes: notes,
    );
    await docRef.set(model.toFirestore());
    return model;
  }

  /// Saves a photo whose URL is already known (e.g. in tests or when URL is
  /// provided externally).
  Future<ProgressPhotoModel> save(ProgressPhoto photo) async {
    final docRef = _db.collection('progressPhotos').doc();
    final model = ProgressPhotoModel.fromEntity(photo.copyWith(id: docRef.id));
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<List<ProgressPhotoModel>> getByDate(
      String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _db
        .collection('progressPhotos')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.map(ProgressPhotoModel.fromFirestore).toList();
  }

  Future<List<ProgressPhotoModel>> getTimeline(String userId, int limit) async {
    final snap = await _db
        .collection('progressPhotos')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(ProgressPhotoModel.fromFirestore).toList();
  }

  Future<List<ProgressPhotoModel>> getByAngle(
      String userId, PhotoAngle angle) async {
    final snap = await _db
        .collection('progressPhotos')
        .where('userId', isEqualTo: userId)
        .where('angle', isEqualTo: angle.name)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(ProgressPhotoModel.fromFirestore).toList();
  }
}
