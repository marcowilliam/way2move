import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/features/journal/data/datasources/journal_audio_storage_datasource.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

/// Minimal fake UploadTask that completes immediately.
class _FakeUploadTask extends Fake implements UploadTask {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(TaskSnapshot) onValue, {
    Function? onError,
  }) {
    final fakeSnap = _FakeTaskSnapshot();
    return Future.value(fakeSnap).then(onValue, onError: onError);
  }
}

class _FakeTaskSnapshot extends Fake implements TaskSnapshot {}

void main() {
  late MockFirebaseStorage mockStorage;
  late MockReference mockRef;
  late JournalAudioStorageDatasource datasource;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockRef = MockReference();
    datasource = JournalAudioStorageDatasource(mockStorage);

    when(() => mockStorage.ref(any())).thenReturn(mockRef);
    when(() => mockRef.putFile(any(), any()))
        .thenAnswer((_) => _FakeUploadTask());
    when(() => mockRef.getDownloadURL())
        .thenAnswer((_) async => 'https://storage.example.com/audio.m4a');
  });

  setUpAll(() {
    registerFallbackValue(SettableMetadata(contentType: 'audio/mp4'));
    registerFallbackValue(File(''));
  });

  group('JournalAudioStorageDatasource', () {
    test('uploadAudio uses correct storage path', () async {
      final file = File('/tmp/journal_audio_12345.m4a');

      await datasource.uploadAudio(audioFile: file, userId: 'user-abc');

      verify(() => mockStorage
          .ref('users/user-abc/journals/journal_audio_12345.m4a')).called(1);
    });

    test('uploadAudio returns download URL from Firebase', () async {
      final file = File('/tmp/journal_audio_12345.m4a');

      final url = await datasource.uploadAudio(audioFile: file, userId: 'u1');

      expect(url, 'https://storage.example.com/audio.m4a');
    });

    test('uploadAudio sets audio/mp4 content type', () async {
      final file = File('/tmp/audio.m4a');

      await datasource.uploadAudio(audioFile: file, userId: 'u1');

      final captured = verify(
        () => mockRef.putFile(
          any(),
          captureAny(),
        ),
      ).captured;

      final metadata = captured.first as SettableMetadata;
      expect(metadata.contentType, 'audio/mp4');
    });
  });
}
