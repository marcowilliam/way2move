import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../nutrition/domain/entities/meal.dart' as nutrition;
import '../../../nutrition/data/repositories/meal_repository_impl.dart';
import '../../../sessions/data/repositories/session_repository_impl.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../sessions/domain/usecases/create_session.dart';
import '../../../nutrition/domain/usecases/create_meal.dart';
import '../../data/repositories/journal_repository_impl.dart';
import '../../domain/services/entity_extraction_service.dart';

class ReviewAutoCreatedPage extends ConsumerStatefulWidget {
  final String journalId;
  final List<ExtractedSession> sessions;
  final List<ExtractedMeal> meals;
  final List<ExtractedBodyMention> bodyMentions;

  const ReviewAutoCreatedPage({
    super.key,
    required this.journalId,
    required this.sessions,
    required this.meals,
    required this.bodyMentions,
  });

  @override
  ConsumerState<ReviewAutoCreatedPage> createState() =>
      _ReviewAutoCreatedPageState();
}

class _ReviewAutoCreatedPageState extends ConsumerState<ReviewAutoCreatedPage> {
  late List<_ReviewSession> _sessions;
  late List<_ReviewMeal> _meals;
  late List<ExtractedBodyMention> _bodyMentions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sessions = widget.sessions
        .map((s) => _ReviewSession(session: s, included: true))
        .toList();
    _meals =
        widget.meals.map((m) => _ReviewMeal(meal: m, included: true)).toList();
    _bodyMentions = List.from(widget.bodyMentions);
  }

  int get _totalItems {
    final includedSessions = _sessions.where((s) => s.included).length;
    final includedMeals = _meals.where((m) => m.included).length;
    return includedSessions + includedMeals + _bodyMentions.length;
  }

  nutrition.MealType _toNutritionMealType(MealType type) => switch (type) {
        MealType.breakfast => nutrition.MealType.breakfast,
        MealType.lunch => nutrition.MealType.lunch,
        MealType.dinner => nutrition.MealType.dinner,
        MealType.snack => nutrition.MealType.snack,
        MealType.drink => nutrition.MealType.drink,
        MealType.general => nutrition.MealType.snack,
      };

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    setState(() => _saving = true);

    final sessionRepo = ref.read(sessionRepositoryProvider);
    final mealRepo = ref.read(mealRepositoryProvider);
    final journalRepo = ref.read(journalRepositoryProvider);
    final createdIds = <String>[];
    final now = DateTime.now();

    // Create session documents
    for (final item in _sessions.where((s) => s.included)) {
      final session = Session(
        id: '',
        userId: userId,
        date: now,
        status: SessionStatus.completed,
        exerciseBlocks: const [],
        focus: item.session.activityType,
        durationMinutes: item.session.durationMinutes,
        notes: item.session.rawText,
      );
      final result = await CreateSession(sessionRepo)(session);
      result.fold((_) {}, (s) => createdIds.add(s.id));
    }

    // Create meal documents
    for (final item in _meals.where((m) => m.included)) {
      final meal = nutrition.Meal(
        id: '',
        userId: userId,
        date: now,
        mealType: _toNutritionMealType(item.mealType),
        description: item.meal.description,
        stomachFeeling: item.meal.stomachFeeling,
        source: 'voice',
        linkedJournalId: widget.journalId,
      );
      final result = await CreateMeal(mealRepo)(meal);
      result.fold((_) {}, (m) => createdIds.add(m.id));
    }

    // Store created entity IDs back in the journal
    if (createdIds.isNotEmpty) {
      await journalRepo.updateAutoCreatedEntities(widget.journalId, createdIds);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Created ${createdIds.length} item${createdIds.length == 1 ? '' : 's'} from your journal.'),
      ),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: AppKeys.reviewAutoCreatedPage,
      appBar: AppBar(
        title: const Text('Review Your Journal Insights'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                "We found these from your journal. Edit or remove what doesn't look right.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // ── Training Activities ──────────────────────────────────────
          if (_sessions.isNotEmpty) ...[
            _SectionHeader(title: 'Training Activities', theme: theme),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = _sessions[i];
                  return _SessionCard(
                    item: item,
                    onRemove: () => setState(() => _sessions.removeAt(i)),
                    onToggle: (val) => setState(() => item.included = val),
                    theme: theme,
                    colorScheme: colorScheme,
                  );
                },
                childCount: _sessions.length,
              ),
            ),
          ],

          // ── Meals ────────────────────────────────────────────────────
          if (_meals.isNotEmpty) ...[
            _SectionHeader(title: 'Meals', theme: theme),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = _meals[i];
                  return _MealCard(
                    item: item,
                    onRemove: () => setState(() => _meals.removeAt(i)),
                    onToggle: (val) => setState(() => item.included = val),
                    onMealTypeChange: (type) =>
                        setState(() => item.mealType = type),
                    theme: theme,
                    colorScheme: colorScheme,
                  );
                },
                childCount: _meals.length,
              ),
            ),
          ],

          // ── Body Awareness ───────────────────────────────────────────
          if (_bodyMentions.isNotEmpty) ...[
            _SectionHeader(title: 'Body Awareness', theme: theme),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bodyMentions.map((m) {
                    final isNegative = m.sentiment == 'negative';
                    return Chip(
                      avatar: Icon(
                        isNegative
                            ? Icons.warning_amber
                            : Icons.check_circle_outline,
                        size: 16,
                        color: isNegative
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                      label: Text('${m.bodyRegion} (${m.sentiment})'),
                      backgroundColor: isNegative
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _bodyMentions.remove(m)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // Spacer for bottom actions
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Skip
              TextButton(
                key: AppKeys.journalSkipButton,
                onPressed: _saving ? null : () => Navigator.maybePop(context),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 12),
              // Save & Create
              Expanded(
                child: FilledButton(
                  key: AppKeys.journalSaveCreateButton,
                  onPressed: (_totalItems > 0 && !_saving) ? _save : null,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save & Create $_totalItems item${_totalItems == 1 ? '' : 's'}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;
  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          title,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Review data holders ───────────────────────────────────────────────────────

class _ReviewSession {
  final ExtractedSession session;
  bool included;
  _ReviewSession({required this.session, required this.included});
}

class _ReviewMeal {
  final ExtractedMeal meal;
  bool included;
  MealType mealType;
  _ReviewMeal({required this.meal, required this.included})
      : mealType = meal.guessedMealType;
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final _ReviewSession item;
  final VoidCallback onRemove;
  final void Function(bool) onToggle;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _SessionCard({
    required this.item,
    required this.onRemove,
    required this.onToggle,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.session.activityType,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Switch(
                  value: item.included,
                  onChanged: onToggle,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                ),
              ],
            ),
            if (item.session.durationMinutes != null)
              Text(
                'Duration: ${item.session.durationMinutes} min',
                style: theme.textTheme.bodySmall,
              ),
            if (item.session.bodyArea != null)
              Text(
                'Body area: ${item.session.bodyArea}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Meal card ─────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final _ReviewMeal item;
  final VoidCallback onRemove;
  final void Function(bool) onToggle;
  final void Function(MealType) onMealTypeChange;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _MealCard({
    required this.item,
    required this.onRemove,
    required this.onToggle,
    required this.onMealTypeChange,
    required this.theme,
    required this.colorScheme,
  });

  String _stomachLabel(int s) => switch (s) {
        1 => 'Very poor',
        2 => 'Poor',
        3 => 'Okay',
        4 => 'Good',
        _ => 'Great',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.meal.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: item.included,
                  onChanged: onToggle,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Meal type dropdown
            DropdownButton<MealType>(
              value: item.mealType,
              isDense: true,
              onChanged: (t) {
                if (t != null) onMealTypeChange(t);
              },
              items: MealType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_mealTypeLabel(t)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Stomach feeling chips
            Row(
              children: [
                Text('Stomach: ', style: theme.textTheme.bodySmall),
                const SizedBox(width: 4),
                Chip(
                  label: Text(_stomachLabel(item.meal.stomachFeeling)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: item.meal.stomachFeeling <= 2
                      ? Colors.red.shade50
                      : item.meal.stomachFeeling >= 4
                          ? Colors.green.shade50
                          : Colors.grey.shade200,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _mealTypeLabel(MealType t) => switch (t) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
        MealType.drink => 'Drink',
        MealType.general => 'General',
      };
}
