import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/meal.dart';
import '../models/meal_model.dart';

class FirestoreMealDatasource {
  final FirebaseFirestore _db;
  FirestoreMealDatasource(this._db);

  Future<MealModel> create(Meal meal) async {
    final docRef = _db.collection('meals').doc();
    final model = MealModel.fromEntity(meal.copyWith(id: docRef.id));
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<MealModel> update(Meal meal) async {
    final model = MealModel.fromEntity(meal);
    await _db.collection('meals').doc(meal.id).update(model.toFirestore());
    return model;
  }

  Future<void> delete(String mealId) async {
    await _db.collection('meals').doc(mealId).delete();
  }

  Future<List<MealModel>> getByDate(String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snap = await _db
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    return snap.docs.map(MealModel.fromFirestore).toList();
  }

  Future<List<MealModel>> getByDateRange(
      String userId, DateTime start, DateTime end) async {
    final snap = await _db
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    return snap.docs.map(MealModel.fromFirestore).toList();
  }

  Future<List<MealModel>> getHistory(String userId, {int limit = 100}) async {
    final snap = await _db
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map(MealModel.fromFirestore).toList();
  }
}
