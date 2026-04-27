/// Post-session body-awareness capture. Lives next to the Session entity
/// because every session can have one.
///
/// "Body listening" frame: free-text areas that felt good vs struggled,
/// a 1-5 overall feel, and a free-text reflection. Distinct from the
/// existing RPE (effort) and the existing journal entries (broader life
/// log) — this is specifically *what the body told you during this session*.
class SensationFeedback {
  /// Free-text labels for areas that responded well — e.g. "left glute",
  /// "thoracic", "hip flexor".
  final List<String> goodAreas;

  /// Free-text labels for areas that resisted or felt wrong — e.g. "neck
  /// gripping", "right SI joint".
  final List<String> strugglingAreas;

  /// 1-5 scale. 1 = body fought me the whole time, 5 = everything sang.
  /// Null while the user hasn't filled it yet (session can be "logged" but
  /// "sensation pending").
  final int? overallFeel;

  /// Optional free-text reflection. Kept short by the UI but uncapped here.
  final String? notes;

  const SensationFeedback({
    this.goodAreas = const [],
    this.strugglingAreas = const [],
    this.overallFeel,
    this.notes,
  });

  bool get isEmpty =>
      goodAreas.isEmpty &&
      strugglingAreas.isEmpty &&
      overallFeel == null &&
      (notes == null || notes!.isEmpty);

  SensationFeedback copyWith({
    List<String>? goodAreas,
    List<String>? strugglingAreas,
    int? overallFeel,
    String? notes,
  }) =>
      SensationFeedback(
        goodAreas: goodAreas ?? this.goodAreas,
        strugglingAreas: strugglingAreas ?? this.strugglingAreas,
        overallFeel: overallFeel ?? this.overallFeel,
        notes: notes ?? this.notes,
      );

  @override
  bool operator ==(Object other) =>
      other is SensationFeedback &&
      _listEq(other.goodAreas, goodAreas) &&
      _listEq(other.strugglingAreas, strugglingAreas) &&
      other.overallFeel == overallFeel &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(goodAreas),
        Object.hashAll(strugglingAreas),
        overallFeel,
        notes,
      );

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
