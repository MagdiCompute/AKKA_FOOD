import '../entities/leaderboard_entry.dart';
import '../entities/leaderboard_period.dart';

/// Abstract repository interface for leaderboard data access.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implementations live in `data/repositories/`.
abstract class ILeaderboardRepository {
  /// Returns a real-time stream of the top 100 [LeaderboardEntry] items
  /// ranked by score descending for the given [period].
  ///
  /// The stream emits a new list whenever the underlying data changes.
  Stream<List<LeaderboardEntry>> watchLeaderboard(LeaderboardPeriod period);

  /// Returns a one-time fetch of the top 100 [LeaderboardEntry] items
  /// ranked by score descending for the given [period].
  Future<List<LeaderboardEntry>> getLeaderboard(LeaderboardPeriod period);

  /// Returns the current authenticated user's [LeaderboardEntry] for the
  /// given [period], including their rank and score.
  ///
  /// Works for users both inside and outside the top 100.
  /// Returns `null` if the user has no score data for the period.
  Future<LeaderboardEntry?> getCurrentUserEntry(LeaderboardPeriod period);
}
