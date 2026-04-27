import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/week_plan.dart';
import '../models/week_plan_model.dart';

class FirestoreWeekPlanDatasource {
  final FirebaseFirestore _db;
  FirestoreWeekPlanDatasource(this._db);

  String _docId(String userId, String isoYearWeek) => '${userId}_$isoYearWeek';

  Future<WeekPlanModel?> getWeekPlan(
    String userId,
    String isoYearWeek,
  ) async {
    final doc = await _db
        .collection('weekPlans')
        .doc(_docId(userId, isoYearWeek))
        .get();
    if (!doc.exists) return null;
    return WeekPlanModel.fromFirestore(doc);
  }

  Stream<WeekPlanModel?> watchWeekPlan(
    String userId,
    String isoYearWeek,
  ) {
    return _db
        .collection('weekPlans')
        .doc(_docId(userId, isoYearWeek))
        .snapshots()
        .map((doc) => doc.exists ? WeekPlanModel.fromFirestore(doc) : null);
  }

  Future<WeekPlanModel> create(WeekPlan plan) async {
    final id = _docId(plan.userId, plan.isoYearWeek);
    final model = WeekPlanModel.fromEntity(plan.copyWith(id: id));
    await _db.collection('weekPlans').doc(id).set(model.toFirestore());
    return model;
  }

  Future<WeekPlanModel> update(WeekPlan plan) async {
    final model = WeekPlanModel.fromEntity(plan);
    await _db.collection('weekPlans').doc(plan.id).update(model.toFirestore());
    return model;
  }
}
