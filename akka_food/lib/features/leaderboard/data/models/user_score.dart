/// Data-layer model representing a Firestore `/userScores/{uid}` document.
///
/// Firestore structure:
/// ```
/// /userScores/{uid}
///   - allTimeScore: number
///   - monthlyScore: number   // reset monthly by scheduled function
///   - weeklyScore: number    // reset weekly by scheduled function
///   - leaderboardVisible: bool
/// ```
///
/// This class is immutable and provides [fromMap]/[toMap] for Firestore
/// serialization, [copyWith] for creating modified copies, and value equality.
class UserScore {
  const UserScore({
    required this.allTimeScore,
    required this.monthlyScore,
    required this.weeklyScore,
    this.leaderboardVisible = true,
  });

  /// Total completed orders all-time.
  final int allTimeScore;

  /// Completed orders this month (reset monthly by scheduled function).
  final int monthlyScore;

  /// Completed orders this week (reset weekly by scheduled function).
  final int weeklyScore;

  /// Whether this user appears on the leaderboard. Defaults to `true`.
  final bool leaderboardVisible;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  /// Creates a [UserScore] from a Firestore document snapshot map.
  ///
  /// Missing or null numeric fields default to `0`.
  /// Missing or null [leaderboardVisible] defaults to `true`.
  factory UserScore.fromMap(Map<String, dynamic> map) {
    return UserScore(
      allTimeScore: (map['allTimeScore'] as num?)?.toInt() ?? 0,
      monthlyScore: (map['monthlyScore'] as num?)?.toInt() ?? 0,
      weeklyScore: (map['weeklyScore'] as num?)?.toInt() ?? 0,
      leaderboardVisible: map['leaderboardVisible'] as bool? ?? true,
    );
  }

  /// Serializes this [UserScore] to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'allTimeScore': allTimeScore,
      'monthlyScore': monthlyScore,
      'weeklyScore': weeklyScore,
      'leaderboardVisible': leaderboardVisible,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Creates a copy of this [UserScore] with the given fields replaced.
  UserScore copyWith({
    int? allTimeScore,
    int? monthlyScore,
    int? weeklyScore,
    bool? leaderboardVisible,
  }) {
    return UserScore(
      allTimeScore: allTimeScore ?? this.allTimeScore,
      monthlyScore: monthlyScore ?? this.monthlyScore,
      weeklyScore: weeklyScore ?? this.weeklyScore,
      leaderboardVisible: leaderboardVisible ?? this.leaderboardVisible,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & toString
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserScore &&
        other.allTimeScore == allTimeScore &&
        other.monthlyScore == monthlyScore &&
        other.weeklyScore == weeklyScore &&
        other.leaderboardVisible == leaderboardVisible;
  }

  @override
  int get hashCode => Object.hash(
        allTimeScore,
        monthlyScore,
        weeklyScore,
        leaderboardVisible,
      );

  @override
  String toString() {
    return 'UserScore('
        'allTimeScore: $allTimeScore, '
        'monthlyScore: $monthlyScore, '
        'weeklyScore: $weeklyScore, '
        'leaderboardVisible: $leaderboardVisible)';
  }
}
