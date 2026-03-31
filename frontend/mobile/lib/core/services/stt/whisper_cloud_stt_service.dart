import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

import 'stt_service.dart';

/// Cloud STT via OpenAI Whisper, proxied through the `transcribeAudio`
/// Firebase callable function.
///
/// Audio is recorded externally (by [VoiceInputWidget] via [AudioRecordingService]).
/// On [stopListening], the recorded M4A file is base64-encoded and sent to the
/// Cloud Function which returns the Whisper transcript.
///
/// [onPartialResult] is never invoked — Whisper is a batch API.
/// The final transcript is only available after [stopListening] resolves.
class WhisperCloudSttService implements SttService {
  final FirebaseFunctions _functions;

  WhisperCloudSttService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  bool get supportsLiveTranscription => false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startListening({
    required void Function(String text) onPartialResult,
  }) async {
    // No-op: audio is captured externally; Whisper is batch-only.
  }

  @override
  Future<String> stopListening({String? audioPath}) async {
    if (audioPath == null) return '';

    try {
      final file = File(audioPath);
      if (!file.existsSync()) return '';

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final result = await _functions
          .httpsCallable('transcribeAudio')
          .call<Map<String, dynamic>>({
        'audioBase64': base64Audio,
        'mimeType': 'audio/m4a',
      });

      return (result.data['transcript'] as String?) ?? '';
    } catch (_) {
      // Fall through — caller is responsible for falling back to device STT.
      return '';
    }
  }

  @override
  void dispose() {}
}
