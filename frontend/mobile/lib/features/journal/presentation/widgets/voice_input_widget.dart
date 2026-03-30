import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Animated mic button + live transcription widget.
/// Calls [onTranscription] whenever the transcribed text changes.
/// Handles microphone permission gracefully.
class VoiceInputWidget extends StatefulWidget {
  final void Function(String text) onTranscription;

  const VoiceInputWidget({super.key, required this.onTranscription});

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();

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
      await _speech.stop();
      _pulseController.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _permissionDenied = false;
    });
    _pulseController.repeat(reverse: true);

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

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
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
