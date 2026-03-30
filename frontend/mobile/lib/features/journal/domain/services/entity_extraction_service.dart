// Pure-Dart entity extraction service — no Flutter or Firebase imports.
// Uses simple keyword matching to extract training sessions, meals, and body
// awareness mentions from free-text journal entries.

// ── Data classes ─────────────────────────────────────────────────────────────

enum MealType { breakfast, lunch, dinner, snack, drink, general }

class ExtractedSession {
  final String activityType;
  final String? bodyArea;
  final int? durationMinutes;
  final String rawText;

  const ExtractedSession({
    required this.activityType,
    this.bodyArea,
    this.durationMinutes,
    required this.rawText,
  });
}

class ExtractedMeal {
  final String description;
  final MealType guessedMealType;
  final int stomachFeeling; // 1-5, default 3
  final String rawText;

  const ExtractedMeal({
    required this.description,
    required this.guessedMealType,
    required this.stomachFeeling,
    required this.rawText,
  });
}

class ExtractedBodyMention {
  final String bodyRegion;
  final String sentiment; // 'positive' | 'negative' | 'neutral'
  final String rawText;

  const ExtractedBodyMention({
    required this.bodyRegion,
    required this.sentiment,
    required this.rawText,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class EntityExtractionService {
  const EntityExtractionService();

  // Keywords that suggest a training activity
  static const _sessionKeywords = [
    'workout',
    'trained',
    'training',
    'session',
    'ran',
    'run',
    'running',
    'lifted',
    'lifting',
    'did',
    'practiced',
    'practice',
    'exercise',
    'exercised',
    'gym',
    'yoga',
    'pilates',
    'worked',
    'working',
    'hiit',
    'crossfit',
    'swim',
    'swam',
    'cycling',
    'biked',
    'walked',
    'hike',
    'hiked',
  ];

  static const _bodyAreas = [
    'hip',
    'hips',
    'shoulder',
    'shoulders',
    'knee',
    'knees',
    'ankle',
    'ankles',
    'back',
    'lower back',
    'upper back',
    'neck',
    'core',
    'glute',
    'glutes',
    'hamstring',
    'hamstrings',
    'quad',
    'quads',
    'chest',
    'foot',
    'feet',
    'wrist',
    'elbow',
  ];

  static const _mealKeywords = [
    'ate',
    'eat',
    'eating',
    'had',
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'drank',
    'drink',
    'drinking',
    'meal',
    'food',
    'coffee',
    'smoothie',
    'shake',
    'protein',
  ];

  static const _stomachNegativeKeywords = [
    'bloated',
    'bloating',
    'pain',
    'painful',
    'cramp',
    'cramping',
    'nausea',
    'nauseous',
    'upset',
    'uncomfortable',
    'bad',
    'gassy',
    'heavy',
    'IBS',
  ];

  static const _stomachPositiveKeywords = [
    'great',
    'good',
    'fine',
    'perfect',
    'well',
    'excellent',
    'amazing',
    'fantastic',
    'light',
  ];

  static const _negativeBodyKeywords = [
    'tight',
    'tightness',
    'pain',
    'painful',
    'sore',
    'soreness',
    'stiff',
    'stiffness',
    'ache',
    'aching',
    'hurt',
    'hurting',
    'discomfort',
    'worse',
  ];

  static const _positiveBodyKeywords = [
    'better',
    'improved',
    'improving',
    'loose',
    'flexible',
    'great',
    'good',
    'strong',
    'recovered',
  ];

  // ── Session extraction ──────────────────────────────────────────────────

  List<ExtractedSession> extractSessions(String text) {
    if (text.isEmpty) return [];
    final lower = text.toLowerCase();

    final foundKeyword = _sessionKeywords
        .cast<String?>()
        .firstWhere((k) => lower.contains(k!), orElse: () => null);
    if (foundKeyword == null) return [];

    final duration = _extractDurationMinutes(lower);
    final bodyArea = _extractBodyArea(lower);

    return [
      ExtractedSession(
        activityType: _inferActivityType(lower, foundKeyword),
        bodyArea: bodyArea,
        durationMinutes: duration,
        rawText: text,
      ),
    ];
  }

  // ── Meal extraction ─────────────────────────────────────────────────────

  List<ExtractedMeal> extractMeals(String text) {
    if (text.isEmpty) return [];
    final lower = text.toLowerCase();

    final foundKeyword = _mealKeywords
        .cast<String?>()
        .firstWhere((k) => lower.contains(k!), orElse: () => null);
    if (foundKeyword == null) return [];

    final mealType = _inferMealType(lower);
    final stomachFeeling = _inferStomachFeeling(lower);

    return [
      ExtractedMeal(
        description: _truncate(text, 100),
        guessedMealType: mealType,
        stomachFeeling: stomachFeeling,
        rawText: text,
      ),
    ];
  }

  // ── Body awareness extraction ───────────────────────────────────────────

  List<ExtractedBodyMention> extractBodyMentions(String text) {
    if (text.isEmpty) return [];
    final lower = text.toLowerCase();

    final results = <ExtractedBodyMention>[];

    for (final area in _bodyAreas) {
      if (!lower.contains(area)) continue;

      // Check for sentiment keywords near this body area mention
      final sentiment = _inferBodySentiment(lower);
      if (sentiment == 'neutral' &&
          !_negativeBodyKeywords.any(lower.contains) &&
          !_positiveBodyKeywords.any(lower.contains)) {
        // No sentiment detected — still add if body region has explicit keyword
        // but only if body keyword + sentiment keyword coexist in the sentence
        continue;
      }

      results.add(
        ExtractedBodyMention(
          bodyRegion: area,
          sentiment: sentiment,
          rawText: text,
        ),
      );
      break; // one mention per text snippet
    }

    return results;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  int? _extractDurationMinutes(String lower) {
    // Match patterns like "30 minutes", "30 mins", "an hour", "1 hour", "2 hours"
    final minuteRegex = RegExp(r'(\d+)\s*(?:minutes?|mins?)');
    final minuteMatch = minuteRegex.firstMatch(lower);
    if (minuteMatch != null) {
      return int.tryParse(minuteMatch.group(1)!);
    }

    final hourRegex = RegExp(r'(\d+)\s*hours?');
    final hourMatch = hourRegex.firstMatch(lower);
    if (hourMatch != null) {
      final hours = int.tryParse(hourMatch.group(1)!);
      if (hours != null) return hours * 60;
    }

    if (lower.contains('an hour') || lower.contains('a hour')) return 60;
    if (lower.contains('half an hour') || lower.contains('half hour')) {
      return 30;
    }

    return null;
  }

  String? _extractBodyArea(String lower) {
    for (final area in _bodyAreas) {
      if (lower.contains(area)) return area;
    }
    return null;
  }

  String _inferActivityType(String lower, String triggerKeyword) {
    if (lower.contains('yoga')) return 'yoga';
    if (lower.contains('pilates')) return 'pilates';
    if (lower.contains('run') || lower.contains('ran')) return 'running';
    if (lower.contains('lift') || lower.contains('weight')) {
      return 'strength training';
    }
    if (lower.contains('swim') || lower.contains('swam')) return 'swimming';
    if (lower.contains('cycl') ||
        lower.contains('bike') ||
        lower.contains('biked')) {
      return 'cycling';
    }
    if (lower.contains('hike') || lower.contains('hiked')) return 'hiking';
    if (lower.contains('walk')) return 'walking';
    if (lower.contains('hiit')) return 'HIIT';
    if (lower.contains('crossfit')) return 'CrossFit';
    return 'workout';
  }

  MealType _inferMealType(String lower) {
    if (lower.contains('breakfast')) return MealType.breakfast;
    if (lower.contains('lunch')) return MealType.lunch;
    if (lower.contains('dinner') || lower.contains('supper')) {
      return MealType.dinner;
    }
    if (lower.contains('snack')) return MealType.snack;
    if (lower.contains('drank') ||
        lower.contains('drink') ||
        lower.contains('coffee') ||
        lower.contains('smoothie') ||
        lower.contains('shake')) {
      return MealType.drink;
    }
    return MealType.general;
  }

  int _inferStomachFeeling(String lower) {
    final hasNegative =
        _stomachNegativeKeywords.any((k) => lower.contains(k.toLowerCase()));
    final hasPositive =
        _stomachPositiveKeywords.any((k) => lower.contains(k.toLowerCase()));

    if (hasNegative && !hasPositive) return 1;
    if (hasPositive && !hasNegative) return 5;
    return 3; // neutral / not mentioned
  }

  String _inferBodySentiment(String lower) {
    final hasNegative =
        _negativeBodyKeywords.any((k) => lower.contains(k.toLowerCase()));
    final hasPositive =
        _positiveBodyKeywords.any((k) => lower.contains(k.toLowerCase()));

    if (hasNegative && !hasPositive) return 'negative';
    if (hasPositive && !hasNegative) return 'positive';
    if (hasPositive && hasNegative) return 'neutral';
    return 'neutral';
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
