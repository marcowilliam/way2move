import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../assessments/domain/entities/compensation_report.dart';
import '../../../assessments/domain/entities/detected_compensation.dart';
import '../../../assessments/domain/entities/assessment.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/entities/program.dart';
import '../../domain/services/program_recommendation_engine.dart';
import '../providers/program_providers.dart';

/// Shows the AI-generated corrective program for user review and optional
/// per-exercise editing before creating it in Firestore.
///
/// Receives [CompensationReport] and [UserProfile] via GoRouter `extra`:
/// ```dart
/// context.push(
///   Routes.aiRecommendation,
///   extra: {'report': report, 'profile': profile},
/// );
/// ```
class AIRecommendationReviewPage extends ConsumerStatefulWidget {
  final CompensationReport report;
  final UserProfile profile;

  const AIRecommendationReviewPage({
    super.key,
    required this.report,
    required this.profile,
  });

  @override
  ConsumerState<AIRecommendationReviewPage> createState() =>
      _AIRecommendationReviewPageState();
}

class _AIRecommendationReviewPageState
    extends ConsumerState<AIRecommendationReviewPage>
    with SingleTickerProviderStateMixin {
  late Program _program;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _program = ProgramRecommendationEngine.generate(
      report: widget.report,
      profile: widget.profile,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Edit helpers ──────────────────────────────────────────────────────────

  void _editExercise(int dayIndex, int entryIndex) {
    final entry =
        _program.weekTemplate.days[dayIndex]!.exerciseEntries[entryIndex];
    final setsController = TextEditingController(text: entry.sets.toString());
    final repsController = TextEditingController(text: entry.reps);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _exerciseLabel(entry.exerciseId),
          style: Theme.of(ctx).textTheme.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sets',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(
                labelText: 'Reps / Duration',
                hintText: 'e.g. 10, 30s, AMRAP',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final sets =
                  int.tryParse(setsController.text.trim()) ?? entry.sets;
              final reps = repsController.text.trim().isEmpty
                  ? entry.reps
                  : repsController.text.trim();
              _updateEntry(
                  dayIndex, entryIndex, entry.copyWith(sets: sets, reps: reps));
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateEntry(int dayIndex, int entryIndex, ExerciseEntry updated) {
    setState(() {
      final day = _program.weekTemplate.days[dayIndex]!;
      final newEntries = [...day.exerciseEntries];
      newEntries[entryIndex] = updated;
      final newDay = day.copyWith(exerciseEntries: newEntries);
      final newDays = {..._program.weekTemplate.days, dayIndex: newDay};
      _program = _program.copyWith(
        weekTemplate: _program.weekTemplate.copyWith(days: newDays),
      );
    });
  }

  void _removeEntry(int dayIndex, int entryIndex) {
    setState(() {
      final day = _program.weekTemplate.days[dayIndex]!;
      final newEntries = [...day.exerciseEntries]..removeAt(entryIndex);
      final newDay = newEntries.isEmpty
          ? DayTemplate.rest
          : day.copyWith(exerciseEntries: newEntries);
      final newDays = {..._program.weekTemplate.days, dayIndex: newDay};
      _program = _program.copyWith(
        weekTemplate: _program.weekTemplate.copyWith(days: newDays),
      );
    });
  }

  // ── Accept ────────────────────────────────────────────────────────────────

  Future<void> _accept() async {
    final notifier = ref.read(createProgramProvider.notifier);
    final saved = await notifier.submit(_program.copyWith(isActive: true));
    if (!mounted) return;
    if (saved != null) {
      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program created — let\'s move!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the program. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = ref.watch(createProgramProvider).isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Your program',
          style: theme.textTheme.displaySmall,
        ),
        centerTitle: false,
        toolbarHeight: 72,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // ── Movement analysis summary ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _SectionHeader(
                  icon: Icons.auto_awesome,
                  label: 'Movement Analysis',
                  subtitle:
                      '${widget.report.detections.length} pattern${widget.report.detections.length == 1 ? '' : 's'} detected',
                ),
              ),
            ),
            if (widget.report.detections.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _EmptyAnalysisCard(theme: theme),
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final detection = widget.report.sortedByPriority[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CompensationCard(detection: detection),
                      );
                    },
                    childCount: widget.report.sortedByPriority.length,
                  ),
                ),
              ),

            // ── Weekly schedule ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _SectionHeader(
                  icon: Icons.calendar_today_outlined,
                  label: 'Weekly Schedule',
                  subtitle: _program.goal,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, dayIndex) {
                    final day = _program.weekTemplate.days[dayIndex]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayCard(
                        dayIndex: dayIndex,
                        day: day,
                        onEditEntry: (entryIndex) =>
                            _editExercise(dayIndex, entryIndex),
                        onRemoveEntry: (entryIndex) =>
                            _removeEntry(dayIndex, entryIndex),
                      ),
                    );
                  },
                  childCount: 7,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AcceptBar(
        isSaving: isSaving,
        onAccept: _accept,
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyAnalysisCard extends StatelessWidget {
  final ThemeData theme;
  const _EmptyAnalysisCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No compensations detected — great baseline movement quality!',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompensationCard extends StatelessWidget {
  final DetectedCompensation detection;
  const _CompensationCard({required this.detection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = detection.severity;
    final color = switch (severity) {
      CompensationSeverity.significant => AppColors.severitySignificant,
      CompensationSeverity.moderate => AppColors.severityModerate,
      CompensationSeverity.mild => AppColors.severityMild,
    };
    final fraction = switch (severity) {
      CompensationSeverity.significant => 1.0,
      CompensationSeverity.moderate => 0.66,
      CompensationSeverity.mild => 0.33,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _patternLabel(detection.pattern),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                _severityLabel(severity),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              color: theme.colorScheme.outlineVariant,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(color: color),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${(detection.frameRatio * 100).round()}% of frames show this pattern',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int dayIndex;
  final DayTemplate day;
  final void Function(int entryIndex) onEditEntry;
  final void Function(int entryIndex) onRemoveEntry;

  const _DayCard({
    required this.dayIndex,
    required this.day,
    required this.onEditEntry,
    required this.onRemoveEntry,
  });

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayName = _dayNames[dayIndex];
    final isRest = day.isRestDay;

    return AnimatedContainer(
      duration: WayMotion.standard,
      decoration: BoxDecoration(
        color: isRest ? theme.colorScheme.surface : AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isRest ? theme.colorScheme.outline : AppColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md - 2,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isRest
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.textOnPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isRest
                          ? AppColors.accent
                          : AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    isRest ? 'Rest' : (day.focus ?? 'Training'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isRest
                          ? theme.colorScheme.onSurface
                          : AppColors.textOnPrimary,
                    ),
                  ),
                ),
                if (!isRest)
                  Text(
                    '${day.exerciseEntries.length} ex',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (!isRest) ...[
            Divider(
              height: 1,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
              color: AppColors.textOnPrimary.withValues(alpha: 0.25),
            ),
            ...day.exerciseEntries.asMap().entries.map(
                  (entry) => _ExerciseRow(
                    index: entry.key,
                    exerciseEntry: entry.value,
                    onEdit: () => onEditEntry(entry.key),
                    onRemove: () => onRemoveEntry(entry.key),
                    onPrimary: true,
                  ),
                ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final ExerciseEntry exerciseEntry;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final bool onPrimary;

  const _ExerciseRow({
    required this.index,
    required this.exerciseEntry,
    required this.onEdit,
    required this.onRemove,
    this.onPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        onPrimary ? AppColors.textOnPrimary : theme.colorScheme.onSurface;
    final mutedColor = onPrimary
        ? AppColors.textOnPrimary.withValues(alpha: 0.65)
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelSmall?.copyWith(color: mutedColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                _exerciseLabel(exerciseEntry.exerciseId),
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: onPrimary
                      ? AppColors.textOnPrimary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${exerciseEntry.sets}×${exerciseEntry.reps}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                foregroundColor: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onAccept;

  const _AcceptBar({required this.isSaving, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm + 4,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: AnimatedSwitcher(
          duration: WayMotion.micro,
          child: isSaving
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('Accept & create program'),
                ),
        ),
      ),
    );
  }
}

// ── Label helpers ────────────────────────────────────────────────────────────

String _patternLabel(CompensationPattern pattern) {
  return switch (pattern) {
    CompensationPattern.forwardHeadPosture => 'Forward Head Posture',
    CompensationPattern.roundedShoulders => 'Rounded Shoulders',
    CompensationPattern.anteriorPelvicTilt => 'Anterior Pelvic Tilt',
    CompensationPattern.posteriorPelvicTilt => 'Posterior Pelvic Tilt',
    CompensationPattern.excessiveLumbarLordosis => 'Excessive Lumbar Lordosis',
    CompensationPattern.thoracicKyphosis => 'Thoracic Kyphosis',
    CompensationPattern.kneeValgus => 'Knee Valgus',
    CompensationPattern.overPronation => 'Over-Pronation',
    CompensationPattern.limitedDorsiflexion => 'Limited Dorsiflexion',
    CompensationPattern.limitedHipInternalRotation =>
      'Limited Hip Internal Rotation',
    CompensationPattern.limitedHipExternalRotation =>
      'Limited Hip External Rotation',
    CompensationPattern.limitedThoracicRotation => 'Limited Thoracic Rotation',
    CompensationPattern.weakGluteMed => 'Weak Glute Med',
    CompensationPattern.poorCoreStability => 'Poor Core Stability',
  };
}

String _severityLabel(CompensationSeverity severity) {
  return switch (severity) {
    CompensationSeverity.mild => 'Mild',
    CompensationSeverity.moderate => 'Moderate',
    CompensationSeverity.significant => 'Significant',
  };
}

String _exerciseLabel(String id) {
  const labels = {
    'ex_chin_tuck': 'Chin Tuck',
    'ex_dns_prone_forearm': 'DNS Prone Forearm',
    'ex_wall_slide': 'Wall Slide',
    'ex_ys_ts': 'Ys & Ts',
    'ex_face_pull': 'Face Pull',
    'ex_90_90_breathing': '90/90 Breathing',
    'ex_deadbug': 'Dead Bug',
    'ex_couch_stretch': 'Couch Stretch',
    'ex_deadbug_alt': 'Dead Bug',
    'ex_bird_dog': 'Bird Dog',
    'ex_plank': 'Plank',
    'ex_rkg_plank': 'RKG Plank',
    'ex_clamshell': 'Clamshell',
    'ex_single_leg_glute_bridge': 'Single-Leg Glute Bridge',
    'ex_hip_90_90': 'Hip 90/90',
    'ex_hip_90_90_lift': 'Hip 90/90 Lift',
    'ex_hip_car': 'Hip CAR',
    'ex_ankle_car': 'Ankle CAR',
    'ex_calf_stretch': 'Calf Stretch',
    'ex_thoracic_rotation': 'Thoracic Rotation',
    'ex_thoracic_extension_bench': 'Thoracic Extension (Bench)',
    'ex_cat_cow': 'Cat-Cow',
    'ex_glute_bridge': 'Glute Bridge',
    'ex_hip_hinge': 'Hip Hinge',
  };
  return labels[id] ??
      id.replaceAll('ex_', '').replaceAll('_', ' ').toUpperCase();
}
