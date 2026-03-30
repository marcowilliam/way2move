import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../goals/presentation/providers/goal_providers.dart';
import '../../domain/entities/progression_suggestion.dart';

class ProgressionSuggestionCard extends ConsumerStatefulWidget {
  final ProgressionSuggestion suggestion;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  const ProgressionSuggestionCard({
    super.key,
    required this.suggestion,
    this.onAccept,
    this.onDismiss,
  });

  @override
  ConsumerState<ProgressionSuggestionCard> createState() =>
      _ProgressionSuggestionCardState();
}

class _ProgressionSuggestionCardState
    extends ConsumerState<ProgressionSuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDeload => widget.suggestion.type == SuggestionType.deload;

  String get _actionText {
    switch (widget.suggestion.action) {
      case ProgressionAction.increaseReps:
        return 'Try adding 2 more reps next time';
      case ProgressionAction.increaseLoad:
        return 'Consider increasing weight by 2.5kg';
      case ProgressionAction.advanceVariation:
        return "You're ready for the next level";
      case ProgressionAction.deload:
        return 'Take it lighter this week — your body needs recovery';
      case ProgressionAction.hold:
        return 'Keep the current level and stay consistent';
    }
  }

  List<Color> get _gradientColors => _isDeload
      ? [const Color(0xFFE67E22), const Color(0xFFD35400)]
      : [AppColors.primary, AppColors.primaryDark];

  Future<void> _handleAccept() async {
    // Attempt to update a linked goal if one exists
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      final goalsAsync = ref.read(goalNotifierProvider);
      final goals = goalsAsync.valueOrNull ?? [];
      final linked = goals
          .where((g) =>
              g.exerciseIds.contains(widget.suggestion.exerciseId) &&
              !g.isAchieved)
          .toList();
      if (linked.isNotEmpty) {
        final goal = linked.first;
        final updated = goal.copyWith(currentValue: goal.currentValue + 1);
        await ref.read(goalNotifierProvider.notifier).updateGoal(updated);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progression saved! Keep it up.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    widget.onAccept?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          key: _isDeload
              ? AppKeys.progressionDeloadCard
              : AppKeys.progressionSuggestionCard,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isDeload ? AppColors.accent : AppColors.primary)
                    .withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gradient header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _isDeload
                            ? Icons.self_improvement_rounded
                            : Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isDeload
                            ? 'Recovery Suggestion'
                            : 'Progression Suggestion',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.suggestion.exerciseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _actionText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.suggestion.reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              key: AppKeys.progressionAcceptButton,
                              onPressed: _handleAccept,
                              child: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              key: AppKeys.progressionDismissButton,
                              onPressed: widget.onDismiss,
                              child: const Text('Dismiss'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
