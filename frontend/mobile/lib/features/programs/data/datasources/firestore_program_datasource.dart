import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/program.dart';
import '../models/program_model.dart';

class FirestoreProgramDatasource {
  final FirebaseFirestore _db;
  FirestoreProgramDatasource(this._db);

  Future<ProgramModel> create(Program program) async {
    final docRef = _db.collection('programs').doc();
    final model = ProgramModel.fromEntity(program.copyWith(id: docRef.id));
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<ProgramModel?> getActive(String userId) async {
    final snap = await _db
        .collection('programs')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ProgramModel.fromFirestore(snap.docs.first);
  }

  Future<ProgramModel> update(Program program) async {
    final model = ProgramModel.fromEntity(program);
    await _db
        .collection('programs')
        .doc(program.id)
        .update(model.toFirestore());
    return model;
  }

  Future<void> deactivate(String programId) async {
    await _db.collection('programs').doc(programId).update({'isActive': false});
  }

  Future<List<ProgramModel>> getHistory(String userId) async {
    final snap = await _db
        .collection('programs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(ProgramModel.fromFirestore).toList();
  }
}
