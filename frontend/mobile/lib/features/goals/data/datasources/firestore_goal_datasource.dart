import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreGoalDatasource {
  final FirebaseFirestore _firestore;

  FirestoreGoalDatasource(this._firestore);

  static const _collection = 'goals';

  Future<DocumentReference> create(Map<String, dynamic> data) =>
      _firestore.collection(_collection).add(data);

  Future<void> update(String goalId, Map<String, dynamic> data) =>
      _firestore.collection(_collection).doc(goalId).update(data);

  Future<DocumentSnapshot> get(String goalId) =>
      _firestore.collection(_collection).doc(goalId).get();

  Future<QuerySnapshot> getAll(String userId) => _firestore
      .collection(_collection)
      .where('userId', isEqualTo: userId)
      .orderBy('meta.updatedAt', descending: true)
      .get();

  Future<QuerySnapshot> getByStatus(String userId, String status) => _firestore
      .collection(_collection)
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: status)
      .get();

  Future<QuerySnapshot> getByCompensation(
          String userId, String compensationId) =>
      _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('compensationIds', arrayContains: compensationId)
          .get();
}
