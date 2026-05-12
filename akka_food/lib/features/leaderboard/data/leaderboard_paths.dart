import '../domain/entities/leaderboard_period.dart';

/// Utility class for generating Firestore document paths for leaderboard
/// documents.
///
/// Firestore structure:
/// ```
/// /leaderboard/all_time
/// /leaderboard/monthly_{YYYY_MM}   (e.g. monthly_2024_06)
/// /leaderboard/weekly_{YYYY_WW}    (e.g. weekly_2024_24)
/// /userScores/{uid}
/// ```
abstract final class LeaderboardPaths {
  /// The Firestore collection name for leaderboard documents.
  static const String collection = 'leaderboard';

  /// The Firestore collection name for user score documents.
  static const String userScoresCollection = 'userScores';

  /// Document ID for the all-time leaderboard.
  static const String allTimeDocId = 'all_time';

  // ---------------------------------------------------------------------------
  // Monthly
  // ---------------------------------------------------------------------------

  /// Returns the Firestore document ID for a monthly leaderboard.
  ///
  /// Format: `monthly_{YYYY_MM}` (e.g. `monthly_2024_06`).
  ///
  /// If [date] is `null`, the current date/time is used.
  static String monthlyDocId([DateTime? date]) {
    final d = date ?? DateTime.now();
    final year = d.year.toString();
    final month = d.month.toString().padLeft(2, '0');
    return 'monthly_${year}_$month';
  }

  /// Returns the full Firestore document path for a monthly leaderboard.
  ///
  /// Example: `leaderboard/monthly_2024_06`.
  static String monthlyPath([DateTime? date]) {
    return '$collection/${monthlyDocId(date)}';
  }

  // ---------------------------------------------------------------------------
  // Weekly
  // ---------------------------------------------------------------------------

  /// Returns the Firestore document ID for a weekly leaderboard.
  ///
  /// Format: `weekly_{YYYY_WW}` (e.g. `weekly_2024_24`).
  /// Week number follows ISO 8601 (Monday-based weeks).
  ///
  /// If [date] is `null`, the current date/time is used.
  static String weeklyDocId([DateTime? date]) {
    final d = date ?? DateTime.now();
    final year = d.year.toString();
    final week = _isoWeekNumber(d).toString().padLeft(2, '0');
    return 'weekly_${year}_$week';
  }

  /// Returns the full Firestore document path for a weekly leaderboard.
  ///
  /// Example: `leaderboard/weekly_2024_24`.
  static String weeklyPath([DateTime? date]) {
    return '$collection/${weeklyDocId(date)}';
  }

  // ---------------------------------------------------------------------------
  // Period-based resolution
  // ---------------------------------------------------------------------------

  /// Returns the Firestore document ID for the given [period].
  ///
  /// If [date] is `null`, the current date/time is used for monthly/weekly.
  static String documentId(LeaderboardPeriod period, [DateTime? date]) {
    switch (period) {
      case LeaderboardPeriod.allTime:
        return allTimeDocId;
      case LeaderboardPeriod.monthly:
        return monthlyDocId(date);
      case LeaderboardPeriod.weekly:
        return weeklyDocId(date);
    }
  }

  /// Returns the full Firestore document path for the given [period].
  ///
  /// Example outputs:
  /// - `leaderboard/all_time`
  /// - `leaderboard/monthly_2024_06`
  /// - `leaderboard/weekly_2024_24`
  static String documentPath(LeaderboardPeriod period, [DateTime? date]) {
    return '$collection/${documentId(period, date)}';
  }

  // ---------------------------------------------------------------------------
  // User Scores
  // ---------------------------------------------------------------------------

  /// Returns the full Firestore document path for a user's score document.
  ///
  /// Example: `userScores/abc123`.
  static String userScorePath(String uid) {
    return '$userScoresCollection/$uid';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Computes the ISO 8601 week number for the given [date].
  ///
  /// ISO weeks start on Monday. Week 1 is the week containing the first
  /// Thursday of the year.
  static int _isoWeekNumber(DateTime date) {
    // Find the Thursday of the current week (ISO weeks are Monday-based).
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    // January 4th is always in week 1 per ISO 8601.
    final jan4 = DateTime(thursday.year, 1, 4);
    final jan4Thursday = jan4.add(Duration(days: DateTime.thursday - jan4.weekday));
    return ((thursday.difference(jan4Thursday).inDays) ~/ 7) + 1;
  }
}
