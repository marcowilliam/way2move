/// Abstract interface for Speech-to-Text transcription.
///
/// Two implementations exist:
/// - [DeviceSttService]: on-device streaming STT via the speech_to_text package.
/// - [WhisperCloudSttService]: batch cloud STT via OpenAI Whisper (callable Cloud Function).
///
/// Use the [sttServiceProvider] to get the appropriate implementation, which is
/// selected via the `use_cloud_stt` Firebase Remote Config flag.
abstract class SttService {
  /// Whether this service calls [onPartialResult] during recording.
  ///
  /// `true` for [DeviceSttService] (streaming), `false` for cloud services
  /// (result only available after [stopListening] completes).
  bool get supportsLiveTranscription;

  /// Returns `true` when the service can accept audio input.
  /// For device STT this checks microphone permissions; for cloud STT it
  /// verifies microphone permission only (network reachability is not checked).
  Future<bool> isAvailable();

  /// Start listening. [onPartialResult] is called with incremental text for
  /// streaming services; it is never called for batch cloud services.
  Future<void> startListening({
    required void Function(String text) onPartialResult,
  });

  /// Stop listening and return the final transcript.
  ///
  /// [audioPath] is the local file path of the recorded audio. Required for
  /// batch cloud services ([WhisperCloudSttService]) and ignored by streaming
  /// services ([DeviceSttService]).
  ///
  /// Returns an empty string if transcription fails or produces no result.
  Future<String> stopListening({String? audioPath});

  /// Release any held resources.
  void dispose();
}
