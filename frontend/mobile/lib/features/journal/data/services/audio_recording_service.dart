import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Wraps the [record] package for starting/stopping audio recording.
/// Records to a temp .m4a file in the app's temp directory.
/// Call [startRecording] when the user begins speaking and [stopRecording]
/// when done — the returned path can be uploaded to Firebase Storage.
class AudioRecordingService {
  final AudioRecorder _recorder;
  // Injected for testability; defaults to path_provider's temp directory.
  final Future<String> Function() _getTempDirPath;

  AudioRecordingService({
    AudioRecorder? recorder,
    Future<String> Function()? getTempDirPath,
  })  : _recorder = recorder ?? AudioRecorder(),
        _getTempDirPath = getTempDirPath ??
            (() async => (await getTemporaryDirectory()).path);

  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Returns `true` if the microphone permission has been granted.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording to a uniquely-named temp file.
  Future<void> startRecording() async {
    final dirPath = await _getTempDirPath();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$dirPath/journal_audio_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
    _isRecording = true;
  }

  /// Stops the active recording and returns the file path, or `null` if
  /// nothing was recording.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  /// Cancels recording without saving.
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.cancel();
      _isRecording = false;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
