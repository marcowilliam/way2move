import '../../../sessions/domain/entities/session.dart' show ExerciseBlock;
import 'workout_enums.dart';

/// A reusable workout template. Distinct from `programs` (multi-week macro
/// plan) and from `sessions` (instance log of an actual workout).
///
/// One workout = one named recipe. Sessions instantiate it; week plans
/// schedule it.
class Workout {
  final String id;
  final String userId;

  final String name;
  final WorkoutKind kind;

  /// Free-text focus — "Anterior chain + flexion", "Cranium release".
  /// Mirrors Notion's workout-level "Joints movements / Primary plane"
  /// hint without forcing a controlled vocabulary at this layer.
  final String? focus;

  /// Planes the workout works in. Reuses the existing `MovementPlane`
  /// vocabulary — kept as `String` here to avoid a domain-layer import
  /// of the exercises feature; data layer maps it to/from the enum.
  final List<String> planeTags;

  /// Free-text intent labels — e.g. "rib stack", "outer hip", "calf
  /// awareness". Used by the week planner's focus-area chips.
  final List<String> intentTags;

  /// Hex color for UI surfaces (matches the Notion dot — 🔵 / 🟢 / 🟡 /
  /// 🟠 / 🔴 for ABCDE). Optional — falls back to brand Terracotta.
  final String? color;

  /// Single emoji or icon name for cards.
  final String? iconEmoji;

  /// Total duration estimate, used to stamp `durationCategory` on derived
  /// sessions and to size cards in the library.
  final int? estimatedMinutes;

  /// The exercise blocks that make up this template. Ordered by
  /// (`phase`, `order`). Sessions copy this list and populate `actualSets`
  /// as the user works through them.
  final List<ExerciseBlock> exerciseBlocks;

  /// Long-form notes (Notion's MD body — total session target, philosophy,
  /// etc.).
  final String? notes;

  /// Created/updated timestamps. Set by the data layer on write.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Workout({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    this.focus,
    this.planeTags = const [],
    this.intentTags = const [],
    this.color,
    this.iconEmoji,
    this.estimatedMinutes,
    this.exerciseBlocks = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Blocks the user has parked for "later" (Notion's Current Included = No).
  /// Used by Workout Detail to render them muted under a "Not yet" section.
  List<ExerciseBlock> get inactiveBlocks =>
      exerciseBlocks.where((b) => b.currentlyIncluded == false).toList();

  /// Blocks the user is actively running. The default view of a workout.
  List<ExerciseBlock> get activeBlocks =>
      exerciseBlocks.where((b) => b.currentlyIncluded != false).toList();

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    WorkoutKind? kind,
    String? focus,
    List<String>? planeTags,
    List<String>? intentTags,
    String? color,
    String? iconEmoji,
    int? estimatedMinutes,
    List<ExerciseBlock>? exerciseBlocks,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Workout(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        focus: focus ?? this.focus,
        planeTags: planeTags ?? this.planeTags,
        intentTags: intentTags ?? this.intentTags,
        color: color ?? this.color,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        exerciseBlocks: exerciseBlocks ?? this.exerciseBlocks,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) => other is Workout && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
