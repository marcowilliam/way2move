import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/session.dart';
import '../models/session_model.dart';

class FirestoreSessionDatasource {
  final FirebaseFirestore _db;
  FirestoreSessionDatasource(this._db);

  Future<SessionModel> create(Session session) async {
    final docRef = _db.collection('sessions').doc();
    final model = SessionModel.fromEntity(session.copyWith(id: docRef.id));
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<SessionModel> update(Session session) async {
    final model = SessionModel.fromEntity(session);
    await _db
        .collection('sessions')
        .doc(session.id)
        .update(model.toFirestore());
    return model;
  }

  Stream<List<SessionModel>> watchByDate(String userId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) => snap.docs.map(SessionModel.fromFirestore).toList());
  }

  Future<List<SessionModel>> getHistory(String userId) async {
    final snap = await _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(SessionModel.fromFirestore).toList();
  }
}
