import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sleep_log_model.dart';

class FirestoreSleepDatasource {
  final FirebaseFirestore _firestore;

  FirestoreSleepDatasource(this._firestore);

  static const _collection = 'sleepLogs';

  Future<DocumentReference> create(Map<String, dynamic> data) =>
      _firestore.collection(_collection).add(data);

  Future<DocumentSnapshot> get(String logId) =>
      _firestore.collection(_collection).doc(logId).get();

  Future<QuerySnapshot> getByUser(String userId, {int limit = 30}) => _firestore
      .collection(_collection)
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .limit(limit)
      .get();

  Future<QuerySnapshot> getByUserSince(String userId, DateTime since) =>
      _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get();

  // ignore: unused_element
  SleepLogModel _mapDoc(DocumentSnapshot doc) =>
      SleepLogModel.fromFirestore(doc);
}
