import '../entities/compensation.dart';

/// Detected mention from journal text.
class CompensationMention {
  final CompensationRegion region;
  final CompensationType type;
  final String rawText;

  const CompensationMention({
    required this.region,
    required this.type,
    required this.rawText,
  });

  @override
  bool operator ==(Object other) =>
      other is CompensationMention &&
      other.region == region &&
      other.type == type;

  @override
  int get hashCode => Object.hash(region, type);
}

/// Keyword-based Phase 1 parser.
/// Scans journal text for body-awareness signals and maps them to
/// CompensationRegion + CompensationType pairs.
abstract class JournalCompensationParser {
  static const _regionKeywords = <CompensationRegion, List<String>>{
    CompensationRegion.cervicalSpine: [
      'neck',
      'cervical',
      'neck pain',
      'stiff neck',
    ],
    CompensationRegion.leftShoulder: [
      'left shoulder',
      'shoulder left',
    ],
    CompensationRegion.rightShoulder: [
      'right shoulder',
      'shoulder right',
    ],
    CompensationRegion.thoracicSpine: [
      'upper back',
      'thoracic',
      'between shoulder blades',
      'mid back',
    ],
    CompensationRegion.lumbarSpine: [
      'lower back',
      'lumbar',
      'low back',
      'back pain',
    ],
    CompensationRegion.pelvis: [
      'hip',
      'pelvis',
      'pelvic',
      'anterior pelvic',
      'posterior pelvic',
    ],
    CompensationRegion.leftHip: [
      'left hip',
      'hip left',
    ],
    CompensationRegion.rightHip: [
      'right hip',
      'hip right',
    ],
    CompensationRegion.leftKnee: [
      'left knee',
      'knee left',
    ],
    CompensationRegion.rightKnee: [
      'right knee',
      'knee right',
    ],
    CompensationRegion.leftAnkle: [
      'left ankle',
      'ankle left',
    ],
    CompensationRegion.rightAnkle: [
      'right ankle',
      'ankle right',
    ],
    CompensationRegion.core: [
      'core',
      'abdominal',
      'stomach muscles',
      'stability',
    ],
  };

  /// Signals that suggest a mobility deficit
  static const _mobilitySignals = [
    'tight',
    'tightness',
    'stiff',
    'stiffness',
    'limited range',
    'can\'t reach',
    'restricted',
    'inflexible',
  ];

  /// Signals that suggest a stability deficit
  static const _stabilitySignals = [
    'unstable',
    'weak',
    'gives way',
    'shaky',
    'wobble',
    'instability',
    'can\'t hold',
  ];

  /// Signals that suggest pain / active compensation
  static const _painSignals = [
    'pain',
    'ache',
    'sore',
    'soreness',
    'hurts',
    'hurting',
    'discomfort',
    'twinge',
    'sharp',
    'burning',
    'tension',
  ];

  /// Signals that suggest improvement (do not create new compensations)
  static const _improvementSignals = [
    'better',
    'improving',
    'improved',
    'resolved',
    'no longer',
    'gone',
    'healed',
    'fixed',
  ];

  /// Parse journal [text] and return a list of unique compensation mentions.
  /// Improvement mentions are flagged separately so callers can update
  /// existing compensations rather than creating new ones.
  static JournalParseResult parse(String text) {
    final lower = text.toLowerCase();
    final newMentions = <CompensationMention>{};
    final improvingRegions = <CompensationRegion>{};

    final hasImprovement = _improvementSignals.any((s) => lower.contains(s));

    for (final entry in _regionKeywords.entries) {
      final region = entry.key;
      final keywords = entry.value;

      final regionMatched = keywords.any((k) => lower.contains(k));
      if (!regionMatched) continue;

      // If an improvement signal appears near the region keyword,
      // flag as improving rather than a new compensation.
      if (hasImprovement) {
        improvingRegions.add(region);
        continue;
      }

      final type = _inferType(lower);
      if (type != null) {
        // Find the raw keyword that matched for context
        final matched = keywords.firstWhere((k) => lower.contains(k));
        newMentions.add(CompensationMention(
          region: region,
          type: type,
          rawText: matched,
        ));
      }
    }

    return JournalParseResult(
      newMentions: newMentions.toList(),
      improvingRegions: improvingRegions.toList(),
    );
  }

  static CompensationType? _inferType(String lower) {
    if (_mobilitySignals.any((s) => lower.contains(s))) {
      return CompensationType.mobilityDeficit;
    }
    if (_stabilitySignals.any((s) => lower.contains(s))) {
      return CompensationType.stabilityDeficit;
    }
    if (_painSignals.any((s) => lower.contains(s))) {
      // Pain without a clearer signal defaults to postural pattern
      return CompensationType.posturalPattern;
    }
    return null;
  }
}

class JournalParseResult {
  final List<CompensationMention> newMentions;
  final List<CompensationRegion> improvingRegions;

  const JournalParseResult({
    required this.newMentions,
    required this.improvingRegions,
  });

  bool get hasNewMentions => newMentions.isNotEmpty;
  bool get hasImprovements => improvingRegions.isNotEmpty;
}
