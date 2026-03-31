import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/nutrition_target_model.dart';

class FirestoreNutritionTargetDatasource {
  final FirebaseFirestore _db;

  const FirestoreNutritionTargetDatasource(this._db);

  Future<NutritionTargetModel?> get(String userId) async {
    final doc = await _db.collection('nutritionTargets').doc(userId).get();
    if (!doc.exists) return null;
    return NutritionTargetModel.fromFirestore(doc);
  }

  Future<NutritionTargetModel> save(NutritionTargetModel model) async {
    final ref = _db.collection('nutritionTargets').doc(model.userId);
    await ref.set(model.toFirestore(), SetOptions(merge: true));
    // Return the model (updatedAt is set server-side; use local time for entity)
    return model;
  }
}
