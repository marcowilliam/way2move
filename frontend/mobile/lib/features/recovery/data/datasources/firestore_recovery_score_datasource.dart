import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/recovery_score_model.dart';

class FirestoreRecoveryScoreDatasource {
  final FirebaseFirestore _db;
  const FirestoreRecoveryScoreDatasource(this._db);

  static String _dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('recoveryScores').doc(userId).collection('daily');

  Future<RecoveryScoreModel?> fetchForDate(String userId, DateTime date) async {
    final doc = await _col(userId).doc(_dateKey(date)).get();
    if (!doc.exists) return null;
    return RecoveryScoreModel.fromFirestore(doc);
  }

  Future<List<RecoveryScoreModel>> fetchTrend(String userId, int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _col(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(RecoveryScoreModel.fromFirestore).toList();
  }

  Future<void> save(RecoveryScoreModel model) async {
    await _col(model.userId).doc(_dateKey(model.date)).set(model.toFirestore());
  }
}
