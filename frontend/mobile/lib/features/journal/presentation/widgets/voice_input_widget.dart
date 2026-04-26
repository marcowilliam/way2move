import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/stt/stt_provider.dart';
import '../../../../core/services/stt/stt_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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

  // Resolved once in initState so dispose() never re-reads the provider after
  // the consumer element is unmounted (which throws StateError under Riverpod).
  late final SttService _stt;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: WayMotion.breath,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 104 / 96).animate(
      CurvedAnimation(parent: _pulseController, curve: WayMotion.easeBreath),
    );

    _stt = widget.sttServiceOverride ?? ref.read(sttServiceProvider);

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isTranscribing ? null : _toggleListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) {
              final scale = _isListening ? _pulseAnimation.value : 1.0;
              final opacity = _isListening
                  ? (1.0 - (_pulseAnimation.value - 1.0) * 0.6)
                  : 1.0;
              return Opacity(
                opacity: opacity.clamp(0.85, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isTranscribing
                          ? AppColors.accent
                          : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isTranscribing
                                  ? AppColors.accent
                                  : AppColors.primary)
                              .withValues(alpha: _isListening ? 0.5 : 0.25),
                          blurRadius: _isListening ? 26 : 12,
                          spreadRadius: _isListening ? 4 : 0,
                        ),
                      ],
                    ),
                    child: _isTranscribing
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: AppColors.textOnPrimary,
                            size: 40,
                          ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        AnimatedSwitcher(
          duration: WayMotion.micro,
          child: _permissionDenied
              ? Text(
                  'Microphone permission denied. Please enable in settings.',
                  key: const ValueKey('denied'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                )
              : Text(
                  _isTranscribing
                      ? 'Transcribing…'
                      : _isListening
                          ? 'Listening…'
                          : 'Tap to speak',
                  key: ValueKey(_isTranscribing
                      ? 'transcribing'
                      : _isListening.toString()),
                  style: theme.textTheme.labelSmall,
                ),
        ),

        if (_liveText.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              _liveText,
              style: AppTypography.fraunces(
                size: 22,
                weight: FontWeight.w400,
                color: theme.colorScheme.onSurface,
                style: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_isListening) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }
}
