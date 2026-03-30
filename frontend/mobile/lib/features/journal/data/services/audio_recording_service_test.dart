import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

import 'package:way2move/features/journal/data/services/audio_recording_service.dart';

class MockAudioRecorder extends Mock implements AudioRecorder {}

void main() {
  late MockAudioRecorder mockRecorder;
  late AudioRecordingService service;

  setUp(() {
    mockRecorder = MockAudioRecorder();
    service = AudioRecordingService(
      recorder: mockRecorder,
      getTempDirPath: () async => '/tmp',
    );
  });

  setUpAll(() {
    registerFallbackValue(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
    );
  });

  group('AudioRecordingService', () {
    test('isRecording is false initially', () {
      expect(service.isRecording, isFalse);
    });

    test('stopRecording returns null when not recording', () async {
      final path = await service.stopRecording();
      expect(path, isNull);
    });

    test('stopRecording returns path from recorder and resets isRecording',
        () async {
      // Arrange: simulate a recording in progress
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(() => mockRecorder.start(any(), path: any(named: 'path')))
          .thenAnswer((_) async {});
      when(() => mockRecorder.stop())
          .thenAnswer((_) async => '/tmp/audio_123.m4a');

      // Act: start then stop
      await service.startRecording();
      final path = await service.stopRecording();

      // Assert
      expect(path, '/tmp/audio_123.m4a');
      expect(service.isRecording, isFalse);
      verify(() => mockRecorder.stop()).called(1);
    });

    test('cancelRecording calls recorder.cancel when recording', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(() => mockRecorder.start(any(), path: any(named: 'path')))
          .thenAnswer((_) async {});
      when(() => mockRecorder.cancel()).thenAnswer((_) async {});

      await service.startRecording();
      await service.cancelRecording();

      expect(service.isRecording, isFalse);
      verify(() => mockRecorder.cancel()).called(1);
    });

    test('cancelRecording does nothing when not recording', () async {
      await service.cancelRecording();
      verifyNever(() => mockRecorder.cancel());
    });

    test('hasPermission delegates to recorder', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
      final result = await service.hasPermission();
      expect(result, isTrue);
    });
  });
}
