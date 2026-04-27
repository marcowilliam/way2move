import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_enums.dart';
import '../models/workout_model.dart';

class FirestoreWorkoutDatasource {
  final FirebaseFirestore _db;
  FirestoreWorkoutDatasource(this._db);

  Future<List<WorkoutModel>> getWorkouts(
    String userId, {
    WorkoutKind? kind,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('workouts').where('userId', isEqualTo: userId);
    if (kind != null) {
      query = query.where('kind', isEqualTo: kind.name);
    }
    final snap = await query.get();
    return snap.docs.map(WorkoutModel.fromFirestore).toList();
  }

  Stream<List<WorkoutModel>> watchWorkouts(
    String userId, {
    WorkoutKind? kind,
  }) {
    Query<Map<String, dynamic>> query =
        _db.collection('workouts').where('userId', isEqualTo: userId);
    if (kind != null) {
      query = query.where('kind', isEqualTo: kind.name);
    }
    return query
        .snapshots()
        .map((snap) => snap.docs.map(WorkoutModel.fromFirestore).toList());
  }

  Future<WorkoutModel?> getWorkoutById(String workoutId) async {
    final doc = await _db.collection('workouts').doc(workoutId).get();
    if (!doc.exists) return null;
    return WorkoutModel.fromFirestore(doc);
  }

  Future<WorkoutModel> create(Workout workout) async {
    final docRef = workout.id.isEmpty
        ? _db.collection('workouts').doc()
        : _db.collection('workouts').doc(workout.id);
    final model = WorkoutModel.fromEntity(workout.copyWith(id: docRef.id));
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<WorkoutModel> update(Workout workout) async {
    final model = WorkoutModel.fromEntity(workout);
    await _db
        .collection('workouts')
        .doc(workout.id)
        .update(model.toFirestore());
    return model;
  }

  Future<void> delete(String workoutId) async {
    await _db.collection('workouts').doc(workoutId).delete();
  }
}
