// lib/features/matches/models/match.dart

class Match {
  /// ID of the matched user (the other person)
  final String otherUserId;

  /// When the match was created (max of both likes)
  final DateTime matchedAt;

  const Match({required this.otherUserId, required this.matchedAt});

  /// For local persistence (Hive, etc.)
  Map<String, dynamic> toJson() => {
    'otherUserId': otherUserId,
    'matchedAt': matchedAt.toIso8601String(),
  };

  /// From local JSON (Hive, cache)
  static Match fromJson(Map<String, dynamic> j) {
    return Match(
      otherUserId: j['otherUserId'] as String,
      matchedAt: DateTime.parse(j['matchedAt'] as String),
    );
  }

  /// From Supabase `matches` view row
  ///
  /// Expected shape:
  /// {
  ///   user_id: <current_user_id>,
  ///   matched_user_id: <other_user_id>,
  ///   matched_at: <timestamp>
  /// }
  static Match fromSupabase(Map<String, dynamic> row) {
    return Match(
      otherUserId: row['matched_user_id'] as String,
      matchedAt: DateTime.parse(row['matched_at'].toString()),
    );
  }
}
