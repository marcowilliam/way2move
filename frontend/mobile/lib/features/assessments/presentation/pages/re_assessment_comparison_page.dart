import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:way2move/features/assessments/domain/entities/assessment_comparison_result.dart';
import 'package:way2move/features/assessments/domain/entities/video_analysis.dart';
import 'package:way2move/features/assessments/presentation/providers/video_analysis_providers.dart';
import 'package:way2move/features/assessments/presentation/widgets/compensation_improvement_card.dart';
import 'package:way2move/features/assessments/presentation/widgets/movement_score_chart.dart';
import 'package:way2move/features/assessments/presentation/widgets/side_by_side_video_player.dart';

/// Full before/after assessment comparison screen.
///
/// Navigate to this page with:
/// ```dart
/// context.push(
///   Routes.assessmentComparison,
///   extra: {
///     'firstAssessmentId': firstId,
///     'secondAssessmentId': secondId,
///   },
/// );
/// ```
class ReAssessmentComparisonPage extends ConsumerStatefulWidget {
  final String firstAssessmentId;
  final String secondAssessmentId;

  const ReAssessmentComparisonPage({
    super.key,
    required this.firstAssessmentId,
    required this.secondAssessmentId,
  });

  @override
  ConsumerState<ReAssessmentComparisonPage> createState() =>
      _ReAssessmentComparisonPageState();
}

class _ReAssessmentComparisonPageState
    extends ConsumerState<ReAssessmentComparisonPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = (
      firstId: widget.firstAssessmentId,
      secondId: widget.secondAssessmentId,
    );
    final comparisonAsync = ref.watch(assessmentComparisonProvider(ids));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement Progress'),
        centerTitle: true,
        elevation: 0,
      ),
      body: comparisonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e),
        data: (comparison) => SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _slideController,
            child: _ComparisonBody(comparison: comparison),
          ),
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final Object error;
  const _ErrorBody({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main comparison body ──────────────────────────────────────────────────────

class _ComparisonBody extends StatelessWidget {
  final AssessmentComparisonResult comparison;
  const _ComparisonBody({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final initialDate = dateFormat.format(comparison.initial.assessmentDate);
    final reDate = dateFormat.format(comparison.reAssessment.assessmentDate);

    final changes = comparison.compensationChanges;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date header
        _SectionCard(
          child: Row(
            children: [
              Expanded(
                child: _DateBadge(label: 'Initial', date: initialDate),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: _DateBadge(label: 'Re-Assessment', date: reDate),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Movement Score Chart
        Text('Movement Scores', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _SectionCard(
          child: MovementScoreChart(comparison: comparison),
        ),
        const SizedBox(height: 16),

        // Video comparison (shows first available movement for both)
        ..._buildVideoSection(context, comparison),

        // Compensation changes
        if (changes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Compensation Changes',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _AnimatedCompensationList(changes: changes),
        ],
      ],
    );
  }

  List<Widget> _buildVideoSection(
      BuildContext context, AssessmentComparisonResult comparison) {
    final initialVideos = comparison.initial.videoAnalyses;
    final reVideos = comparison.reAssessment.videoAnalyses;

    if (initialVideos.isEmpty || reVideos.isEmpty) return [];

    // Find a movement present in both
    VideoAnalysis? initVid;
    VideoAnalysis? reVid;

    for (final movement in ScreeningMovement.values) {
      final i = _findVideo(initialVideos, movement);
      final r = _findVideo(reVideos, movement);
      if (i != null &&
          r != null &&
          i.storageVideoPath != null &&
          r.storageVideoPath != null) {
        initVid = i;
        reVid = r;
        break;
      }
    }

    if (initVid == null || reVid == null) return [];

    final dateFormat = DateFormat('MMM d');
    final initLabel =
        '${initVid.movement.displayName}\n${dateFormat.format(comparison.initial.assessmentDate)}';
    final reLabel =
        '${reVid.movement.displayName}\n${dateFormat.format(comparison.reAssessment.assessmentDate)}';

    return [
      Text('Side-by-Side Video',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      _SectionCard(
        padding: const EdgeInsets.all(8),
        child: SideBySideVideoPlayer(
          initialVideoPath: initVid.storageVideoPath!,
          reAssessmentVideoPath: reVid.storageVideoPath!,
          initialLabel: initLabel,
          reAssessmentLabel: reLabel,
        ),
      ),
    ];
  }

  VideoAnalysis? _findVideo(List<VideoAnalysis> list, ScreeningMovement m) {
    for (final v in list) {
      if (v.movement == m) return v;
    }
    return null;
  }
}

// ── Animated compensation list ────────────────────────────────────────────────

class _AnimatedCompensationList extends StatefulWidget {
  final List<CompensationChange> changes;
  const _AnimatedCompensationList({required this.changes});

  @override
  State<_AnimatedCompensationList> createState() =>
      _AnimatedCompensationListState();
}

class _AnimatedCompensationListState extends State<_AnimatedCompensationList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.changes.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _animations = _controllers
        .map(
          (c) => CurvedAnimation(parent: c, curve: Curves.easeOut),
        )
        .toList();

    // Stagger the entrance
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 60 * i), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.changes.length,
        (i) => FadeTransition(
          opacity: _animations[i],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(_animations[i]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CompensationImprovementCard(change: widget.changes[i]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String label;
  final String date;

  const _DateBadge({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(date, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
