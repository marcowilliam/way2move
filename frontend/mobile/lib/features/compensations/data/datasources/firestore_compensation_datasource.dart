import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/compensation.dart';

class FirestoreCompensationDatasource {
  final FirebaseFirestore _firestore;

  FirestoreCompensationDatasource(this._firestore);

  static const _collection = 'compensations';

  Future<DocumentReference> create(
      String userId, Map<String, dynamic> data) async {
    return _firestore.collection(_collection).add(data);
  }

  Future<void> update(String compensationId, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(compensationId).update(data);
  }

  Future<DocumentSnapshot> get(String compensationId) =>
      _firestore.collection(_collection).doc(compensationId).get();

  Future<QuerySnapshot> getActive(String userId) => _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
        CompensationStatus.active.name,
        CompensationStatus.improving.name
      ]).get();

  Future<QuerySnapshot> getByRegion(String userId, String region) => _firestore
      .collection(_collection)
      .where('userId', isEqualTo: userId)
      .where('region', isEqualTo: region)
      .get();

  Stream<QuerySnapshot> watchByUser(String userId) => _firestore
      .collection(_collection)
      .where('userId', isEqualTo: userId)
      .orderBy('detectedAt', descending: true)
      .snapshots();
}
