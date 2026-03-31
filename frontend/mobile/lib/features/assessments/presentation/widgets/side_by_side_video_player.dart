import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Displays two video players side by side with synchronized scrubbing.
///
/// Both videos play and pause together. A single scrub bar controls both.
/// Assessment date labels are shown above each video.
class SideBySideVideoPlayer extends StatefulWidget {
  /// Path or URL of the initial-assessment video.
  final String initialVideoPath;

  /// Path or URL of the re-assessment video.
  final String reAssessmentVideoPath;

  /// Label displayed above the initial-assessment video.
  final String initialLabel;

  /// Label displayed above the re-assessment video.
  final String reAssessmentLabel;

  const SideBySideVideoPlayer({
    super.key,
    required this.initialVideoPath,
    required this.reAssessmentVideoPath,
    required this.initialLabel,
    required this.reAssessmentLabel,
  });

  @override
  State<SideBySideVideoPlayer> createState() => _SideBySideVideoPlayerState();
}

class _SideBySideVideoPlayerState extends State<SideBySideVideoPlayer> {
  late VideoPlayerController _left;
  late VideoPlayerController _right;
  bool _initialized = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    _left = _buildController(widget.initialVideoPath);
    _right = _buildController(widget.reAssessmentVideoPath);

    await Future.wait([_left.initialize(), _right.initialize()]);

    if (!mounted) return;

    _duration = _left.value.duration;
    _left.addListener(_onLeftUpdate);

    setState(() => _initialized = true);
  }

  VideoPlayerController _buildController(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return VideoPlayerController.networkUrl(Uri.parse(path));
    }
    return VideoPlayerController.asset(path);
  }

  void _onLeftUpdate() {
    if (!mounted) return;
    final pos = _left.value.position;
    if (pos != _position) {
      setState(() => _position = pos);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_playing) {
      await _left.pause();
      await _right.pause();
    } else {
      await _left.play();
      await _right.play();
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  Future<void> _seekTo(double seconds) async {
    final pos = Duration(milliseconds: (seconds * 1000).round());
    await _left.seekTo(pos);
    await _right.seekTo(pos);
  }

  @override
  void dispose() {
    _left.removeListener(_onLeftUpdate);
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final totalSeconds = _duration.inMilliseconds / 1000.0;
    final posSeconds = _position.inMilliseconds / 1000.0;

    return Column(
      children: [
        // Video panels
        Row(
          children: [
            Expanded(
              child: _VideoPanel(
                controller: _left,
                label: widget.initialLabel,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _VideoPanel(
                controller: _right,
                label: widget.reAssessmentLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Scrub bar + play button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                onPressed: _togglePlayPause,
                iconSize: 28,
              ),
              Expanded(
                child: Slider(
                  value: totalSeconds > 0
                      ? posSeconds.clamp(0.0, totalSeconds)
                      : 0.0,
                  min: 0,
                  max: totalSeconds > 0 ? totalSeconds : 1.0,
                  onChanged: totalSeconds > 0 ? _seekTo : null,
                ),
              ),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _VideoPanel extends StatelessWidget {
  final VideoPlayerController controller;
  final String label;

  const _VideoPanel({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ],
    );
  }
}
