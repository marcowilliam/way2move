import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'device_stt_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSpeechToText extends Mock implements SpeechToText {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSpeechToText mockSpeech;
  late DeviceSttService sut;

  setUp(() {
    mockSpeech = MockSpeechToText();
    sut = DeviceSttService(speech: mockSpeech);
  });

  group('DeviceSttService', () {
    test('supportsLiveTranscription is true', () {
      expect(sut.supportsLiveTranscription, isTrue);
    });

    group('isAvailable', () {
      test('returns true when speech initialises successfully', () async {
        when(() => mockSpeech.initialize(onError: any(named: 'onError')))
            .thenAnswer((_) async => true);

        expect(await sut.isAvailable(), isTrue);
      });

      test('returns false when speech initialisation fails', () async {
        when(() => mockSpeech.initialize(onError: any(named: 'onError')))
            .thenAnswer((_) async => false);

        expect(await sut.isAvailable(), isFalse);
      });
    });

    group('startListening', () {
      test('calls speech.listen with dictation mode and en_US locale',
          () async {
        when(() => mockSpeech.listen(
              onResult: any(named: 'onResult'),
              localeId: any(named: 'localeId'),
              listenOptions: any(named: 'listenOptions'),
            )).thenAnswer((_) async {});

        await sut.startListening(onPartialResult: (_) {});

        verify(() => mockSpeech.listen(
              onResult: any(named: 'onResult'),
              localeId: 'en_US',
              listenOptions: any(named: 'listenOptions'),
            )).called(1);
      });

      test('invokes onPartialResult when speech recognises words', () async {
        String? captured;

        // Capture the onResult callback so we can invoke it manually.
        when(() => mockSpeech.listen(
              onResult: any(named: 'onResult'),
              localeId: any(named: 'localeId'),
              listenOptions: any(named: 'listenOptions'),
            )).thenAnswer((invocation) async {
          final cb = invocation.namedArguments[#onResult] as void Function(
              SpeechRecognitionResult);
          cb(SpeechRecognitionResult(
            [const SpeechRecognitionWords('hello world', [], 0.9)],
            true,
          ));
        });

        await sut.startListening(onPartialResult: (t) => captured = t);

        expect(captured, 'hello world');
      });
    });

    group('stopListening', () {
      test('calls speech.stop and returns last recognised text', () async {
        // Arrange: simulate a recognition result captured during startListening.
        when(() => mockSpeech.listen(
              onResult: any(named: 'onResult'),
              localeId: any(named: 'localeId'),
              listenOptions: any(named: 'listenOptions'),
            )).thenAnswer((invocation) async {
          final cb = invocation.namedArguments[#onResult] as void Function(
              SpeechRecognitionResult);
          cb(SpeechRecognitionResult(
            [const SpeechRecognitionWords('final text', [], 0.95)],
            true,
          ));
        });
        when(() => mockSpeech.stop()).thenAnswer((_) async {});

        await sut.startListening(onPartialResult: (_) {});
        final result = await sut.stopListening();

        expect(result, 'final text');
        verify(() => mockSpeech.stop()).called(1);
      });

      test('returns empty string when no words were recognised', () async {
        when(() => mockSpeech.listen(
              onResult: any(named: 'onResult'),
              localeId: any(named: 'localeId'),
              listenOptions: any(named: 'listenOptions'),
            )).thenAnswer((_) async {});
        when(() => mockSpeech.stop()).thenAnswer((_) async {});

        await sut.startListening(onPartialResult: (_) {});
        final result = await sut.stopListening();

        expect(result, '');
      });

      test('audioPath parameter is ignored', () async {
        when(() => mockSpeech.listen(
              onResult: any(named: 'onResult'),
              localeId: any(named: 'localeId'),
              listenOptions: any(named: 'listenOptions'),
            )).thenAnswer((_) async {});
        when(() => mockSpeech.stop()).thenAnswer((_) async {});

        await sut.startListening(onPartialResult: (_) {});
        // Passing audioPath should not throw or change behaviour.
        final result =
            await sut.stopListening(audioPath: '/tmp/irrelevant.m4a');

        expect(result, '');
      });
    });

    group('dispose', () {
      test('cancels speech recognition', () {
        when(() => mockSpeech.cancel()).thenAnswer((_) async {});
        sut.dispose();
        verify(() => mockSpeech.cancel()).called(1);
      });
    });
  });
}
