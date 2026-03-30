import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads a recorded audio file to Firebase Storage and returns
/// the public download URL.
///
/// Storage path: users/{userId}/journals/{filename}
class JournalAudioStorageDatasource {
  final FirebaseStorage _storage;

  const JournalAudioStorageDatasource(this._storage);

  /// Uploads [audioFile] and returns its download URL.
  /// Throws on upload failure — the caller wraps in try/catch.
  Future<String> uploadAudio({
    required File audioFile,
    required String userId,
  }) async {
    final filename = audioFile.path.split('/').last;
    final ref = _storage.ref('users/$userId/journals/$filename');
    await ref.putFile(
      audioFile,
      SettableMetadata(contentType: 'audio/mp4'),
    );
    return ref.getDownloadURL();
  }
}
