import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../domain/entities/journal_entry.dart';
import '../providers/journal_providers.dart';

class JournalHistoryPage extends ConsumerStatefulWidget {
  const JournalHistoryPage({super.key});

  @override
  ConsumerState<JournalHistoryPage> createState() => _JournalHistoryPageState();
}

class _JournalHistoryPageState extends ConsumerState<JournalHistoryPage> {
  JournalType? _filterType; // null = All
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalsAsync = ref.watch(journalNotifierProvider);

    return Scaffold(
      key: AppKeys.journalHistoryPage,
      appBar: AppBar(
        title: const Text('Journal History'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(journalNotifierProvider),
        child: journalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (all) {
            final entries = _filterType == null
                ? all
                : all.where((e) => e.type == _filterType).toList();

            return Column(
              children: [
                // Filter chips
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filterType == null,
                        onTap: () => setState(() => _filterType = null),
                      ),
                      const SizedBox(width: 8),
                      ...JournalType.values.map((t) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: _typeLabel(t),
                              selected: _filterType == t,
                              onTap: () => setState(() => _filterType = t),
                            ),
                          )),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // List
                Expanded(
                  child: entries.isEmpty
                      ? _EmptyState(filtered: _filterType != null)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final entry = entries[i];
                            final expanded = _expandedIds.contains(entry.id);
                            return _JournalCard(
                              entry: entry,
                              expanded: expanded,
                              onTap: () {
                                setState(() {
                                  if (expanded) {
                                    _expandedIds.remove(entry.id);
                                  } else {
                                    _expandedIds.add(entry.id);
                                  }
                                });
                              },
                              colorScheme: colorScheme,
                              theme: theme,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _typeLabel(JournalType type) => switch (type) {
        JournalType.morningCheckIn => 'Morning',
        JournalType.preSession => 'Pre-Session',
        JournalType.postSession => 'Post-Session',
        JournalType.eveningReflection => 'Evening',
        JournalType.general => 'General',
      };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final bool expanded;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _JournalCard({
    required this.entry,
    required this.expanded,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  Color _typeBadgeColor() => switch (entry.type) {
        JournalType.morningCheckIn => Colors.amber.shade100,
        JournalType.preSession => Colors.blue.shade100,
        JournalType.postSession => Colors.green.shade100,
        JournalType.eveningReflection => Colors.purple.shade100,
        JournalType.general => Colors.grey.shade200,
      };

  String _typeName() => switch (entry.type) {
        JournalType.morningCheckIn => 'Morning',
        JournalType.preSession => 'Pre-Session',
        JournalType.postSession => 'Post-Session',
        JournalType.eveningReflection => 'Evening',
        JournalType.general => 'General',
      };

  String _moodEmoji(int mood) =>
      ['😔', '😐', '🙂', '😊', '🤩'][(mood - 1).clamp(0, 4)];

  @override
  Widget build(BuildContext context) {
    final preview = entry.content.length > 100
        ? '${entry.content.substring(0, 100)}...'
        : entry.content;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeBadgeColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _typeName(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                // Date
                Text(
                  DateFormat('MMM d, h:mm a').format(entry.date),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (entry.mood != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _moodEmoji(entry.mood!),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Content
            Text(
              expanded ? entry.content : preview,
              style: theme.textTheme.bodyMedium,
            ),

            // Expanded details
            if (expanded) ...[
              if (entry.painPoints.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: entry.painPoints
                      .map((p) => Chip(
                            label: Text(p),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
            ],

            // Expand indicator
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtered;
  const _EmptyState({required this.filtered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'No entries for this type yet.'
                  : 'No journal entries yet.\nStart by adding your first entry!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
