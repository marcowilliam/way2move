import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/protocol.dart';
import '../models/protocol_model.dart';

class FirestoreProtocolDatasource {
  final FirebaseFirestore _db;
  FirestoreProtocolDatasource(this._db);

  Future<List<ProtocolModel>> getActiveProtocols(String userId) async {
    final snap = await _db
        .collection('protocols')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.map(ProtocolModel.fromFirestore).toList();
  }

  Stream<List<ProtocolModel>> watchActiveProtocols(String userId) {
    return _db
        .collection('protocols')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs.map(ProtocolModel.fromFirestore).toList());
  }

  Future<ProtocolModel?> getProtocolById(String protocolId) async {
    final doc = await _db.collection('protocols').doc(protocolId).get();
    if (!doc.exists) return null;
    return ProtocolModel.fromFirestore(doc);
  }

  Future<ProtocolModel> create(Protocol protocol) async {
    final docRef = protocol.id.isEmpty
        ? _db.collection('protocols').doc()
        : _db.collection('protocols').doc(protocol.id);
    final model = ProtocolModel.fromEntity(protocol.copyWith(id: docRef.id));
    await docRef.set(model.toFirestore());
    return model;
  }

  Future<ProtocolModel> update(Protocol protocol) async {
    final model = ProtocolModel.fromEntity(protocol);
    await _db
        .collection('protocols')
        .doc(protocol.id)
        .update(model.toFirestore());
    return model;
  }

  Future<void> markCompleted(String protocolId) async {
    await _db.collection('protocols').doc(protocolId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
