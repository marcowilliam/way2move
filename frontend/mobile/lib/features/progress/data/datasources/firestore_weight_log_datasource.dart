import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/weight_log.dart';
import '../models/weight_log_model.dart';

class FirestoreWeightLogDatasource {
  final FirebaseFirestore _db;
  FirestoreWeightLogDatasource(this._db);

  Future<WeightLogModel> save(WeightLog log) async {
    final docRef = _db.collection('weightLogs').doc();
    final model = WeightLogModel.fromEntity(log.copyWith(id: docRef.id));
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<List<WeightLogModel>> getLogs(String userId, int limit) async {
    final snap = await _db
        .collection('weightLogs')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(WeightLogModel.fromFirestore).toList();
  }

  Future<List<WeightLogModel>> getTrend(String userId, int daysBack) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysBack));
    final snap = await _db
        .collection('weightLogs')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('date', descending: false)
        .get();
    return snap.docs.map(WeightLogModel.fromFirestore).toList();
  }
}
