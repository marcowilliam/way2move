import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/stt/stt_provider.dart';
import '../../../../core/services/stt/stt_service.dart';
import '../../data/services/audio_recording_service.dart';

/// Animated mic button + live transcription widget.
///
/// Simultaneously:
/// - Captures audio via [AudioRecordingService] (for Firebase Storage upload).
/// - Transcribes speech via the [SttService] from [sttServiceProvider].
///
/// For streaming services (device STT) [onTranscription] is called live during
/// recording. For batch services (Whisper), [onTranscription] is called once
/// after [stopListening] completes — the widget shows a "Transcribing…"
/// indicator in the meantime.
///
/// When recording stops, [onAudioRecorded] is called with the local M4A path
/// so the caller can upload to Firebase Storage.
class VoiceInputWidget extends ConsumerStatefulWidget {
  /// Called whenever transcribed text is updated.
  /// For streaming STT this fires during recording; for cloud STT once at end.
  final void Function(String text) onTranscription;

  /// Called once when recording stops with the local audio file path.
  /// May be null if recording was not started or failed.
  final void Function(String? path)? onAudioRecorded;

  /// Override the STT service — used in tests to inject a fake.
  /// Defaults to [sttServiceProvider] when null.
  final SttService? sttServiceOverride;

  const VoiceInputWidget({
    super.key,
    required this.onTranscription,
    this.onAudioRecorded,
    this.sttServiceOverride,
  });

  @override
  ConsumerState<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends ConsumerState<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecordingService _audioRecorder = AudioRecordingService();

  bool _isListening = false;
  bool _isTranscribing = false;
  bool _isAvailable = false;
  bool _permissionDenied = false;
  String _liveText = '';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  SttService get _stt =>
      widget.sttServiceOverride ?? ref.read(sttServiceProvider);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.stop();
    _initStt();
  }

  Future<void> _initStt() async {
    final available = await _stt.isAvailable();
    if (mounted) setState(() => _isAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (!_isAvailable) {
      setState(() => _permissionDenied = true);
      return;
    }

    if (_isListening) {
      await _stopListening();
      return;
    }

    await _startListening();
  }

  Future<void> _startListening() async {
    final hasMicPermission = await _audioRecorder.hasPermission();

    setState(() {
      _isListening = true;
      _liveText = '';
      _permissionDenied = false;
    });
    _pulseController.repeat(reverse: true);

    if (hasMicPermission) {
      try {
        await _audioRecorder.startRecording();
      } catch (_) {
        // Non-fatal — transcription still works without the audio file.
      }
    }

    await _stt.startListening(
      onPartialResult: (text) {
        if (!mounted) return;
        setState(() => _liveText = text);
        widget.onTranscription(text);
      },
    );
  }

  Future<void> _stopListening() async {
    _pulseController.stop();
    if (mounted) setState(() => _isListening = false);

    String? audioPath;
    try {
      audioPath = await _audioRecorder.stopRecording();
    } catch (_) {
      // Non-fatal.
    }

    // For cloud (batch) STT: show transcribing state while the API call runs.
    if (!_stt.supportsLiveTranscription) {
      if (mounted) setState(() => _isTranscribing = true);
    }

    final transcript = await _stt.stopListening(audioPath: audioPath);

    if (mounted) {
      setState(() {
        _isTranscribing = false;
        if (transcript.isNotEmpty) _liveText = transcript;
      });
    }

    if (transcript.isNotEmpty) {
      widget.onTranscription(transcript);
    }

    widget.onAudioRecorded?.call(audioPath);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stt.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated mic button
        GestureDetector(
          onTap: _isTranscribing ? null : _toggleListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) => Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isTranscribing
                    ? colorScheme.secondary
                    : _isListening
                        ? colorScheme.error
                        : colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_isTranscribing
                            ? colorScheme.secondary
                            : _isListening
                                ? colorScheme.error
                                : colorScheme.primary)
                        .withAlpha(102),
                    blurRadius: _isListening ? 20 : 8,
                    spreadRadius: _isListening ? 4 : 0,
                  ),
                ],
              ),
              child: _isTranscribing
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.onSecondary,
                      ),
                    )
                  : Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: colorScheme.onPrimary,
                      size: 32,
                    ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Status label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _permissionDenied
              ? Text(
                  'Microphone permission denied. Please enable in settings.',
                  key: const ValueKey('denied'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.error),
                  textAlign: TextAlign.center,
                )
              : Text(
                  _isTranscribing
                      ? 'Transcribing…'
                      : _isListening
                          ? 'Listening...'
                          : 'Tap to speak',
                  key: ValueKey(_isTranscribing
                      ? 'transcribing'
                      : _isListening.toString()),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
        ),

        // Live transcription preview
        if (_liveText.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _liveText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}
