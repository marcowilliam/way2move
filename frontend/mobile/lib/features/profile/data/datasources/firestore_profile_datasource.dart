import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProfileDatasource {
  final FirebaseFirestore _firestore;

  FirestoreProfileDatasource(this._firestore);

  Future<DocumentSnapshot> getProfile(String userId) =>
      _firestore.collection('users').doc(userId).get();

  Future<void> updateProfile(
      String userId, Map<String, dynamic> data) =>
      _firestore.collection('users').doc(userId).update(data);

  Stream<DocumentSnapshot> watchProfile(String userId) =>
      _firestore.collection('users').doc(userId).snapshots();
}
