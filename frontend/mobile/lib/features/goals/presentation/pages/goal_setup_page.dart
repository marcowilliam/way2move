import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../assessments/domain/entities/assessment.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_providers.dart';
import '../widgets/add_goal_dialog.dart';

class GoalSetupPage extends ConsumerStatefulWidget {
  /// The assessment ID that triggered setup. Used to load compensation patterns.
  final String? fromAssessmentId;

  const GoalSetupPage({super.key, this.fromAssessmentId});

  @override
  ConsumerState<GoalSetupPage> createState() => _GoalSetupPageState();
}

class _GoalSetupPageState extends ConsumerState<GoalSetupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  final Set<int> _selectedIndices = {};
  List<Goal> _suggestedGoals = [];
  bool _hasLoadedSuggestions = false;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // Build suggestions from a few common patterns for demo purposes.
    // In production, these come from the assessment's compensationResults.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSuggestions());
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _loadSuggestions() {
    // Use all available patterns as suggestions for setup page
    final useCase = ref.read(getSuggestedGoalsUseCaseProvider);
    final patterns = CompensationPattern.values
        .where((p) => _kMappedPatterns.contains(p))
        .toList();
    setState(() {
      _suggestedGoals = useCase.call(patterns);
      _hasLoadedSuggestions = true;
    });
    _staggerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);

    return Scaffold(
      key: AppKeys.goalSetupPage,
      appBar: AppBar(
        title: const Text('Set Up Your Goals'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            key: AppKeys.goalSetupDoneButton,
            onPressed: _done,
            child: const Text('Done'),
          ),
        ],
      ),
      body: _hasLoadedSuggestions
          ? Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Based on your assessment, here are suggested goals. Tap any to add them to your plan.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                      ..._suggestedGoals.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final delay = idx * 0.08;
                        final animation = CurvedAnimation(
                          parent: _staggerController,
                          curve: Interval(
                            delay.clamp(0.0, 0.9),
                            (delay + 0.4).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        );
                        return _AnimatedSuggestedGoalCard(
                          goal: entry.value,
                          animation: animation,
                          isSelected: _selectedIndices.contains(idx),
                          onToggle: () => setState(() {
                            if (_selectedIndices.contains(idx)) {
                              _selectedIndices.remove(idx);
                            } else {
                              _selectedIndices.add(idx);
                            }
                          }),
                        );
                      }),
                    ],
                  ),
                ),
                _BottomBar(
                  selectedCount: _selectedIndices.length,
                  onAddSelected: () => _addSelected(uid),
                  onAddCustom: () {
                    if (uid == null) return;
                    showDialog<void>(
                      context: context,
                      builder: (_) => AddGoalDialog(userId: uid),
                    );
                  },
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _addSelected(String? uid) async {
    if (uid == null || _selectedIndices.isEmpty) {
      _done();
      return;
    }

    final notifier = ref.read(goalNotifierProvider.notifier);
    for (final idx in _selectedIndices) {
      final template = _suggestedGoals[idx];
      await notifier.createGoal(template.copyWith(userId: uid, id: ''));
    }

    if (!mounted) return;
    _done();
  }

  void _done() => context.go(Routes.home);
}

/// Set of CompensationPattern values that have suggestion templates.
const _kMappedPatterns = {
  CompensationPattern.forwardHeadPosture,
  CompensationPattern.roundedShoulders,
  CompensationPattern.anteriorPelvicTilt,
  CompensationPattern.poorCoreStability,
  CompensationPattern.weakGluteMed,
  CompensationPattern.limitedDorsiflexion,
  CompensationPattern.thoracicKyphosis,
  CompensationPattern.kneeValgus,
  CompensationPattern.limitedHipInternalRotation,
  CompensationPattern.overPronation,
};

class _AnimatedSuggestedGoalCard extends StatelessWidget {
  final Goal goal;
  final Animation<double> animation;
  final bool isSelected;
  final VoidCallback onToggle;

  const _AnimatedSuggestedGoalCard({
    required this.goal,
    required this.animation,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: _SuggestedGoalCard(
          goal: goal,
          isSelected: isSelected,
          onToggle: onToggle,
        ),
      ),
    );
  }
}

class _SuggestedGoalCard extends StatelessWidget {
  final Goal goal;
  final bool isSelected;
  final VoidCallback onToggle;

  const _SuggestedGoalCard({
    required this.goal,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${goal.targetValue.toStringAsFixed(goal.targetValue.truncateToDouble() == goal.targetValue ? 0 : 1)} ${goal.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onAddSelected;
  final VoidCallback onAddCustom;

  const _BottomBar({
    required this.selectedCount,
    required this.onAddSelected,
    required this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0)
            FilledButton(
              onPressed: onAddSelected,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                  'Add $selectedCount goal${selectedCount == 1 ? '' : 's'}'),
            ),
          if (selectedCount > 0) const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAddCustom,
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Goal'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
