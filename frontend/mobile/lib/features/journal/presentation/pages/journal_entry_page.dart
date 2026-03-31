import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/services/entity_extraction_service.dart';
import '../providers/journal_providers.dart';
import '../widgets/voice_input_widget.dart';

class JournalEntryPage extends ConsumerStatefulWidget {
  final JournalType type;
  final String? linkedSessionId;

  const JournalEntryPage({
    super.key,
    this.type = JournalType.general,
    this.linkedSessionId,
  });

  @override
  ConsumerState<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends ConsumerState<JournalEntryPage> {
  final _contentController = TextEditingController();
  int? _mood;
  int? _energyLevel;
  final List<String> _painPoints = [];
  bool _isSaving = false;
  String? _recordedAudioPath; // local file path from AudioRecordingService

  static const _painPointOptions = [
    'neck',
    'shoulders',
    'lower back',
    'hips',
    'knees',
    'ankles',
  ];

  static const _moodEmojis = ['😔', '😐', '🙂', '😊', '🤩'];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.type) {
        JournalType.morningCheckIn => 'Morning Check-In',
        JournalType.preSession => 'Pre-Session',
        JournalType.postSession => 'Post-Session Reflection',
        JournalType.eveningReflection => 'Evening Reflection',
        JournalType.general => 'Journal Entry',
      };

  String get _prompt => switch (widget.type) {
        JournalType.morningCheckIn => 'How did you sleep? How do you feel?',
        JournalType.preSession => 'What will you focus on today?',
        JournalType.postSession =>
          'How did your session go? Any pain or tightness?',
        JournalType.eveningReflection => 'Summarize your day. What went well?',
        JournalType.general => "What's on your mind?",
      };

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content first.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Upload audio recording if one was captured.
    String? audioUrl;
    if (_recordedAudioPath != null) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        try {
          final audioStorage = ref.read(journalAudioStorageProvider);
          audioUrl = await audioStorage.uploadAudio(
            audioFile: File(_recordedAudioPath!),
            userId: userId,
          );
        } catch (_) {
          // Non-fatal — save without audio URL if upload fails.
        }
      }
    }

    // Build a temporary id — Firestore will replace with real doc id
    final entry = JournalEntry(
      id: '',
      userId: '',
      date: DateTime.now(),
      type: widget.type,
      content: content,
      audioUrl: audioUrl,
      mood: _mood,
      energyLevel: _energyLevel,
      painPoints: List.from(_painPoints),
      linkedSessionId: widget.linkedSessionId,
    );

    final notifier = ref.read(journalNotifierProvider.notifier);
    final result = await notifier.create(entry);

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save journal entry.')),
        );
      },
      (saved) {
        // Check if we should run entity extraction
        final shouldExtract = (widget.type == JournalType.postSession ||
                widget.type == JournalType.eveningReflection ||
                widget.type == JournalType.general) &&
            content.length > 50;

        if (shouldExtract) {
          const extractor = EntityExtractionService();
          final sessions = extractor.extractSessions(content);
          final meals = extractor.extractMeals(content);
          final bodyMentions = extractor.extractBodyMentions(content);
          final hasEntities = sessions.isNotEmpty ||
              meals.isNotEmpty ||
              bodyMentions.isNotEmpty;

          if (hasEntities) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Analyzing your journal...'),
                duration: Duration(seconds: 1),
              ),
            );
            // Navigate to review page (requires GoRouter in production)
            try {
              context.push(
                Routes.reviewAutoCreated,
                extra: {
                  'journalId': saved.id,
                  'sessions': sessions,
                  'meals': meals,
                  'bodyMentions': bodyMentions,
                },
              );
            } catch (_) {
              // GoRouter not available (e.g. in tests) — just pop
              if (Navigator.canPop(context)) Navigator.pop(context);
            }
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal saved!')),
        );
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: AppKeys.journalEntryPage,
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              key: AppKeys.journalSaveButton,
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contextual prompt
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _prompt,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Linked session indicator
          if (widget.linkedSessionId != null) ...[
            Chip(
              avatar: const Icon(Icons.link, size: 16),
              label: const Text('Linked to today\'s session'),
              backgroundColor: colorScheme.secondaryContainer,
              labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 16),
          ],

          // Voice input — simultaneously transcribes and records audio.
          Center(
            child: VoiceInputWidget(
              onTranscription: (text) {
                setState(() {
                  _contentController.text = text;
                  _contentController.selection = TextSelection.collapsed(
                    offset: text.length,
                  );
                });
              },
              onAudioRecorded: (path) {
                setState(() => _recordedAudioPath = path);
              },
            ),
          ),

          // Audio recording indicator
          if (_recordedAudioPath != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.audio_file, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Audio recorded — will upload with entry',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                      ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Text field (mirrors voice transcription, also directly editable)
          TextField(
            key: AppKeys.journalContentField,
            controller: _contentController,
            maxLines: 6,
            minLines: 4,
            decoration: InputDecoration(
              hintText: 'Type or speak your entry...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
            ),
          ),

          const SizedBox(height: 28),

          // Mood selector
          Text('Mood (optional)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final value = i + 1;
              final selected = _mood == value;
              return GestureDetector(
                onTap: () => setState(() => _mood = selected ? null : value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Text(
                    _moodEmojis[i],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Energy level
          Text('Energy level (optional)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.battery_0_bar, size: 20),
              Expanded(
                child: Slider(
                  value: (_energyLevel ?? 3).toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _energyLevel?.toString() ?? '3',
                  onChanged: (v) => setState(() => _energyLevel = v.round()),
                ),
              ),
              const Icon(Icons.battery_full, size: 20),
            ],
          ),

          const SizedBox(height: 24),

          // Pain points
          Text('Pain points (optional)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _painPointOptions.map((point) {
              final selected = _painPoints.contains(point);
              return FilterChip(
                label: Text(point),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _painPoints.add(point);
                    } else {
                      _painPoints.remove(point);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Save button
          FilledButton(
            key: AppKeys.journalSaveButton,
            onPressed: _isSaving ? null : _save,
            child: const Text('Save Journal Entry'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
