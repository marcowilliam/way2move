import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'whisper_cloud_stt_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a temporary M4A file with dummy bytes and returns its path.
Future<String> _createTempAudio() async {
  final dir = Directory.systemTemp;
  final file = File(
      '${dir.path}/test_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
  await file.writeAsBytes(utf8.encode('fake audio data'));
  return file.path;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late WhisperCloudSttService sut;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    sut = WhisperCloudSttService(functions: mockFunctions);

    when(() => mockFunctions.httpsCallable('transcribeAudio'))
        .thenReturn(mockCallable);
  });

  group('WhisperCloudSttService', () {
    test('supportsLiveTranscription is false', () {
      expect(sut.supportsLiveTranscription, isFalse);
    });

    test('isAvailable returns true', () async {
      expect(await sut.isAvailable(), isTrue);
    });

    group('startListening', () {
      test('does not call onPartialResult (batch service)', () async {
        bool called = false;
        await sut.startListening(onPartialResult: (_) => called = true);
        expect(called, isFalse);
      });
    });

    group('stopListening', () {
      test('returns empty string when audioPath is null', () async {
        final result = await sut.stopListening();
        expect(result, '');
        verifyNever(() => mockFunctions.httpsCallable(any()));
      });

      test('returns empty string when audio file does not exist', () async {
        final result =
            await sut.stopListening(audioPath: '/nonexistent/path.m4a');
        expect(result, '');
        verifyNever(() => mockFunctions.httpsCallable(any()));
      });

      test('calls transcribeAudio function with base64-encoded audio',
          () async {
        final audioPath = await _createTempAudio();
        addTearDown(() => File(audioPath).deleteSync());

        final mockResult = MockHttpsCallableResult();
        when(() => mockResult.data).thenReturn({'transcript': 'I ate a salad'});
        when(() => mockCallable.call<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => mockResult);

        final result = await sut.stopListening(audioPath: audioPath);

        expect(result, 'I ate a salad');

        final captured =
            verify(() => mockCallable.call<Map<String, dynamic>>(captureAny()))
                .captured;
        final payload = captured.first as Map<String, dynamic>;
        expect(payload['mimeType'], 'audio/m4a');
        // Verify base64 is non-empty and decodable.
        expect(() => base64Decode(payload['audioBase64'] as String),
            returnsNormally);
      });

      test('returns empty string when Cloud Function call throws', () async {
        final audioPath = await _createTempAudio();
        addTearDown(() => File(audioPath).deleteSync());

        when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
          FirebaseFunctionsException(
            message: 'internal',
            code: 'internal',
          ),
        );

        final result = await sut.stopListening(audioPath: audioPath);
        expect(result, '');
      });

      test('returns empty string when transcript is missing from response',
          () async {
        final audioPath = await _createTempAudio();
        addTearDown(() => File(audioPath).deleteSync());

        final mockResult = MockHttpsCallableResult();
        when(() => mockResult.data).thenReturn({'transcript': null});
        when(() => mockCallable.call<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => mockResult);

        final result = await sut.stopListening(audioPath: audioPath);
        expect(result, '');
      });
    });

    group('dispose', () {
      test('does not throw', () {
        expect(() => sut.dispose(), returnsNormally);
      });
    });
  });
}
