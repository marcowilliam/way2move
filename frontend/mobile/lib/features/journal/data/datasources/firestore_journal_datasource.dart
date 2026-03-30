import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreJournalDatasource {
  final FirebaseFirestore _firestore;

  FirestoreJournalDatasource(this._firestore);

  static const _collection = 'journals';

  Future<DocumentReference> create(Map<String, dynamic> data) =>
      _firestore.collection(_collection).add(data);

  Future<QuerySnapshot> getByDate(String userId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: false)
        .get();
  }

  Future<QuerySnapshot> getByType(
    String userId,
    String type, {
    int limit = 20,
  }) =>
      _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

  Future<QuerySnapshot> getForSession(String userId, String sessionId) =>
      _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('linkedSessionId', isEqualTo: sessionId)
          .orderBy('date', descending: false)
          .get();

  Future<QuerySnapshot> getHistory(String userId, {int limit = 50}) =>
      _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

  Future<void> updateAutoCreatedEntities(
    String journalId,
    List<String> entityIds,
  ) =>
      _firestore
          .collection(_collection)
          .doc(journalId)
          .update({'autoCreatedEntities': entityIds});

  Future<QuerySnapshot> getByMonth(String userId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
  }
}
