import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProgressionRuleDatasource {
  final FirebaseFirestore _db;
  static const _collection = 'progressionRules';

  FirestoreProgressionRuleDatasource(this._db);

  String _docId(String userId, String exerciseId) => '${userId}_$exerciseId';

  String _globalDocId(String userId) => '${userId}_global';

  Future<DocumentSnapshot> getRule(String userId, String exerciseId) {
    return _db.collection(_collection).doc(_docId(userId, exerciseId)).get();
  }

  Future<DocumentSnapshot> getGlobalRule(String userId) {
    return _db.collection(_collection).doc(_globalDocId(userId)).get();
  }

  Future<void> setRule(
      String userId, String exerciseId, Map<String, dynamic> data) {
    return _db
        .collection(_collection)
        .doc(_docId(userId, exerciseId))
        .set(data, SetOptions(merge: true));
  }

  Future<void> setGlobalRule(String userId, Map<String, dynamic> data) {
    return _db
        .collection(_collection)
        .doc(_globalDocId(userId))
        .set(data, SetOptions(merge: true));
  }
}
