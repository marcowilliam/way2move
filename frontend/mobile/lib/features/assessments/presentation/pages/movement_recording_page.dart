import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/video_analysis.dart';
import '../../domain/usecases/analyze_movement_video.dart';
import '../providers/video_analysis_providers.dart';

// ── Previous score helper ─────────────────────────────────────────────────────

/// Returns the previous % clean frames for [movement] from [previousAnalyses],
/// or null if not available.
double? _previousScoreFor(
  ScreeningMovement movement,
  List<VideoAnalysis>? previousAnalyses,
) {
  if (previousAnalyses == null) return null;
  try {
    final analysis = previousAnalyses.firstWhere(
      (a) => a.movement == movement,
    );
    if (analysis.frames.isEmpty) return null;
    // Use detection rate: frames with any landmarks detected are "clean"
    final clean = analysis.frames.where((f) => f.landmarks.isNotEmpty).length;
    return (clean / analysis.frames.length * 100).roundToDouble();
  } catch (_) {
    return null;
  }
}

// ── Page entry point ─────────────────────────────────────────────────────────

/// Guides the user through all five screening movements, records a short
/// video clip for each, then triggers the analysis pipeline.
///
/// Requires [assessmentId] and [userId] to link results to an assessment.
class MovementRecordingPage extends ConsumerStatefulWidget {
  final String assessmentId;
  final String userId;

  /// When true, shows the previous score banner before recording each movement.
  final bool isReAssessment;

  /// Previous analyses from the last assessment — used to show previous scores.
  final List<VideoAnalysis>? previousAnalyses;

  const MovementRecordingPage({
    super.key,
    required this.assessmentId,
    required this.userId,
    this.isReAssessment = false,
    this.previousAnalyses,
  });

  @override
  ConsumerState<MovementRecordingPage> createState() =>
      _MovementRecordingPageState();
}

class _MovementRecordingPageState extends ConsumerState<MovementRecordingPage>
    with TickerProviderStateMixin {
  // Movement sequence
  static const _movements = ScreeningMovement.values;
  int _currentIndex = 0;
  ScreeningMovement get _currentMovement => _movements[_currentIndex];

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isRecording = false;

  // Recording state
  String? _lastRecordedPath;
  final Map<ScreeningMovement, String> _recordedPaths = {};

  // Countdown
  int _countdown = 0;
  Timer? _countdownTimer;

  // Analysis
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  int _analysedCount = 0;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _enterController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);

    _initCamera();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _enterController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Camera setup ───────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Prefer front camera for self-assessment
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraReady = true);
        _enterController.forward();
      }
    } catch (_) {
      // Camera unavailable — allow continuing without preview
      if (mounted) setState(() => _isCameraReady = false);
    }
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  Future<void> _startCountdownThenRecord() async {
    setState(() => _countdown = 3);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _startRecording();
      }
    });
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showNoCameraFallback();
      return;
    }
    await _cameraController!.startVideoRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;
    final xfile = await _cameraController!.stopVideoRecording();
    setState(() {
      _isRecording = false;
      _lastRecordedPath = xfile.path;
      _recordedPaths[_currentMovement] = xfile.path;
    });
  }

  void _showNoCameraFallback() {
    // Mark as "skipped" with a placeholder path — analysis will return empty frames
    setState(() {
      _recordedPaths[_currentMovement] = '';
    });
    _advanceOrFinish();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _advanceOrFinish() {
    if (_currentIndex < _movements.length - 1) {
      setState(() {
        _currentIndex++;
        _lastRecordedPath = null;
        _countdown = 0;
      });
      _enterController
        ..reset()
        ..forward();
    } else {
      _runAnalysisPipeline();
    }
  }

  void _retakeClip() {
    setState(() {
      _lastRecordedPath = null;
      _recordedPaths.remove(_currentMovement);
      _countdown = 0;
    });
  }

  // ── Analysis pipeline ──────────────────────────────────────────────────────

  Future<void> _runAnalysisPipeline() async {
    setState(() {
      _isAnalyzing = true;
      _analysedCount = 0;
      _analysisProgress = 0.0;
    });

    final notifier = ref.read(analyzeMovementVideoProvider.notifier);

    for (final movement in _movements) {
      final path = _recordedPaths[movement];
      if (path == null || path.isEmpty) {
        setState(() => _analysedCount++);
        continue;
      }

      // Compress before uploading
      String compressedPath = path;
      try {
        final info = await VideoCompress.compressVideo(
          path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (info?.path != null) compressedPath = info!.path!;
      } catch (_) {
        // Proceed with original if compression fails
      }

      await notifier.analyze(
        AnalyzeMovementVideoInput(
          localVideoPath: compressedPath,
          assessmentId: widget.assessmentId,
          userId: widget.userId,
          movement: movement,
          onAnalysisProgress: (p) {
            if (mounted) {
              setState(() =>
                  _analysisProgress = (_analysedCount + p) / _movements.length);
            }
          },
        ),
      );

      if (mounted) setState(() => _analysedCount++);
    }

    setState(() => _isAnalyzing = false);

    if (mounted) {
      context.pop(true); // return true = completed successfully
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return _AnalysisProgressOverlay(progress: _analysisProgress);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isCameraReady && _cameraController != null)
            FadeTransition(
              opacity: _fadeIn,
              child: CameraPreview(_cameraController!),
            )
          else
            const _CameraUnavailablePlaceholder(),

          // Dark gradient overlay at top and bottom
          const _GradientOverlay(),

          // Top bar
          _TopBar(
            currentIndex: _currentIndex,
            totalMovements: _movements.length,
            movement: _currentMovement,
            previousScore: widget.isReAssessment
                ? _previousScoreFor(_currentMovement, widget.previousAnalyses)
                : null,
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: _lastRecordedPath != null
                  ? _ReviewControls(
                      onRetake: _retakeClip,
                      onAccept: _advanceOrFinish,
                      isLast: _currentIndex == _movements.length - 1,
                    )
                  : _RecordingControls(
                      countdown: _countdown,
                      isRecording: _isRecording,
                      pulseAnimation: _pulseAnimation,
                      onTap: _isRecording
                          ? _stopRecording
                          : _countdown > 0
                              ? null
                              : _startCountdownThenRecord,
                    ),
            ),
          ),

          // Countdown overlay
          if (_countdown > 0 && !_isRecording)
            _CountdownOverlay(count: _countdown),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final int currentIndex;
  final int totalMovements;
  final ScreeningMovement movement;

  /// % clean frames from the previous assessment for this movement, or null.
  final double? previousScore;

  const _TopBar({
    required this.currentIndex,
    required this.totalMovements,
    required this.movement,
    this.previousScore,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress dots
              Row(
                children: List.generate(totalMovements, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == currentIndex ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i < currentIndex
                          ? AppColors.accentGreen
                          : i == currentIndex
                              ? Colors.white
                              : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Movement ${currentIndex + 1} of $totalMovements',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                movement.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  movement.instruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              if (previousScore != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last time you scored ${previousScore!.toStringAsFixed(0)}% clean',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingControls extends StatelessWidget {
  final int countdown;
  final bool isRecording;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;

  const _RecordingControls({
    required this.countdown,
    required this.isRecording,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          if (isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 10),
                  SizedBox(width: 6),
                  Text(
                    'REC',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Tap to start recording',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onTap,
            child: ScaleTransition(
              scale: isRecording
                  ? pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording ? Colors.red : Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: isRecording
                    ? const Icon(Icons.stop, color: Colors.white, size: 36)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewControls extends StatelessWidget {
  final VoidCallback onRetake;
  final VoidCallback onAccept;
  final bool isLast;

  const _ReviewControls({
    required this.onRetake,
    required this.onAccept,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
              SizedBox(width: 8),
              Text('Clip recorded',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRetake,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isLast ? 'Analyse' : 'Next movement'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int count;
  const _CountdownOverlay({required this.count});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Text(
          '$count',
          key: ValueKey(count),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 120,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CameraUnavailablePlaceholder extends StatelessWidget {
  const _CameraUnavailablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, color: Colors.white38, size: 64),
            SizedBox(height: 16),
            Text(
              'Camera unavailable',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisProgressOverlay extends StatelessWidget {
  final double progress;
  const _AnalysisProgressOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 64),
              const SizedBox(height: 32),
              const Text(
                'Analysing your movement',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Running on-device AI — this takes a moment',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
