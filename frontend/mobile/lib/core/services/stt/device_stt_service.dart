import 'package:speech_to_text/speech_to_text.dart';

import 'stt_service.dart';

/// On-device speech-to-text using the [speech_to_text] package.
///
/// Provides real-time partial results via [onPartialResult] during recording.
/// The final recognised text is returned by [stopListening].
class DeviceSttService implements SttService {
  final SpeechToText _speech;
  String _lastResult = '';

  DeviceSttService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  @override
  bool get supportsLiveTranscription => true;

  @override
  Future<bool> isAvailable() async {
    return _speech.initialize(onError: (_) {});
  }

  @override
  Future<void> startListening({
    required void Function(String text) onPartialResult,
  }) async {
    _lastResult = '';
    await _speech.listen(
      onResult: (result) {
        _lastResult = result.recognizedWords;
        onPartialResult(_lastResult);
      },
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation),
    );
  }

  @override
  Future<String> stopListening({String? audioPath}) async {
    await _speech.stop();
    return _lastResult;
  }

  @override
  void dispose() {
    _speech.cancel();
  }
}
