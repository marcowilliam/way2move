import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../data/services/audio_recording_service.dart';

/// Animated mic button + live transcription widget.
///
/// Simultaneously runs:
/// - speech_to_text for on-device transcription (calls [onTranscription])
/// - AudioRecordingService to record audio to a local file
///
/// When listening stops, [onAudioRecorded] is called with the local file path
/// so the caller can upload to Firebase Storage.
class VoiceInputWidget extends StatefulWidget {
  /// Called whenever transcribed text changes.
  final void Function(String text) onTranscription;

  /// Called once when recording stops with the local audio file path.
  /// May be null if recording was not started or failed.
  final void Function(String? path)? onAudioRecorded;

  const VoiceInputWidget({
    super.key,
    required this.onTranscription,
    this.onAudioRecorded,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final AudioRecordingService _audioRecorder = AudioRecordingService();

  bool _isListening = false;
  bool _isAvailable = false;
  bool _permissionDenied = false;
  String _liveText = '';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

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
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
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
      _permissionDenied = false;
    });
    _pulseController.repeat(reverse: true);

    // Start audio recording alongside STT.
    if (hasMicPermission) {
      try {
        await _audioRecorder.startRecording();
      } catch (_) {
        // Non-fatal — transcription still works without the audio file.
      }
    }

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final text = result.recognizedWords;
        setState(() => _liveText = text);
        widget.onTranscription(text);
      },
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _pulseController.stop();

    String? audioPath;
    try {
      audioPath = await _audioRecorder.stopRecording();
    } catch (_) {
      // Non-fatal — we still have the transcription.
    }

    if (mounted) setState(() => _isListening = false);

    widget.onAudioRecorded?.call(audioPath);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
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
          onTap: _toggleListening,
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
                color: _isListening ? colorScheme.error : colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isListening ? colorScheme.error : colorScheme.primary)
                            .withAlpha(102),
                    blurRadius: _isListening ? 20 : 8,
                    spreadRadius: _isListening ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
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
                  _isListening ? 'Listening...' : 'Tap to speak',
                  key: ValueKey(_isListening),
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
