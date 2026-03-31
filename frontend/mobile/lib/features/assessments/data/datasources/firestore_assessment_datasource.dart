import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/assessment.dart';
import '../models/assessment_model.dart';

class FirestoreAssessmentDatasource {
  final FirebaseFirestore _db;
  FirestoreAssessmentDatasource(this._db);

  Future<AssessmentModel> create(Assessment assessment) async {
    final docRef = _db.collection('assessments').doc();
    final model =
        AssessmentModel.fromEntity(assessment.copyWith(id: docRef.id));
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<AssessmentModel?> getLatest(String userId) async {
    final snap = await _db
        .collection('assessments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AssessmentModel.fromFirestore(snap.docs.first);
  }

  Future<AssessmentModel?> getById(String id) async {
    final doc = await _db.collection('assessments').doc(id).get();
    if (!doc.exists) return null;
    return AssessmentModel.fromFirestore(doc);
  }

  Future<List<AssessmentModel>> getHistory(String userId) async {
    final snap = await _db
        .collection('assessments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(AssessmentModel.fromFirestore).toList();
  }

  Future<WeeklyPulseModel> logPulse(WeeklyPulse pulse) async {
    final docRef = _db.collection('weeklyPulses').doc();
    final model = WeeklyPulseModel.fromEntity(
      WeeklyPulse(
        id: docRef.id,
        userId: pulse.userId,
        date: pulse.date,
        energyScore: pulse.energyScore,
        sorenessScore: pulse.sorenessScore,
        motivationScore: pulse.motivationScore,
        sleepQualityScore: pulse.sleepQualityScore,
        notes: pulse.notes,
      ),
    );
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<WeeklyPulseModel?> getLatestPulse(String userId) async {
    final snap = await _db
        .collection('weeklyPulses')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return WeeklyPulseModel.fromFirestore(snap.docs.first);
  }
}
