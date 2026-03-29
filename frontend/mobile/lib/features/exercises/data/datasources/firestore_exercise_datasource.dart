import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exercise_model.dart';
import 'exercise_seed_data.dart';

class FirestoreExerciseDatasource {
  final FirebaseFirestore _db;

  FirestoreExerciseDatasource(this._db);

  Future<List<ExerciseModel>> fetchExercises() async {
    final snap = await _db.collection('exercises').get();
    return snap.docs.map(ExerciseModel.fromFirestore).toList();
  }

  Future<ExerciseModel> fetchExerciseById(String id) async {
    final doc = await _db.collection('exercises').doc(id).get();
    if (!doc.exists) throw Exception('Exercise not found: $id');
    return ExerciseModel.fromFirestore(doc);
  }

  Future<ExerciseModel> addCustomExercise(ExerciseModel model) async {
    final ref = _db.collection('exercises').doc();
    final withId = ExerciseModel(
      id: ref.id,
      name: model.name,
      description: model.description,
      videoUrl: model.videoUrl,
      sportTags: model.sportTags,
      patternTags: model.patternTags,
      regionTags: model.regionTags,
      typeTags: model.typeTags,
      equipmentTags: model.equipmentTags,
      difficulty: model.difficulty,
      progressionIds: model.progressionIds,
      regressionIds: model.regressionIds,
      cues: model.cues,
      isCustom: true,
      createdByUserId: model.createdByUserId,
    );
    await ref.set(withId.toFirestore());
    return withId;
  }

  /// Returns seed exercises from local data (no Firestore call).
  List<ExerciseModel> getSeedExercises() {
    return kSeedExercises
        .map((data) => ExerciseModel.fromMap(
              data,
              data['id'] as String,
            ))
        .toList();
  }
}
