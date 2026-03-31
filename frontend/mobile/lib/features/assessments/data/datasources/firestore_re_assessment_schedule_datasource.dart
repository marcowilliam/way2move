import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/re_assessment_schedule_model.dart';

class FirestoreReAssessmentScheduleDatasource {
  final FirebaseFirestore _db;
  static const _collection = 'reAssessmentSchedules';

  FirestoreReAssessmentScheduleDatasource(this._db);

  Future<ReAssessmentScheduleModel?> getSchedule(String userId) async {
    final doc = await _db.collection(_collection).doc(userId).get();
    if (!doc.exists) return null;
    return ReAssessmentScheduleModel.fromFirestore(doc);
  }

  Future<void> updateInterval(String userId, int intervalWeeks) async {
    await _db
        .collection(_collection)
        .doc(userId)
        .update({'intervalWeeks': intervalWeeks});
  }
}
