/// Represents the three time windows for leaderboard ranking.
///
/// Used by the state management layer to switch between period views.
/// - [allTime] — cumulative ranking since the beginning
/// - [monthly] — ranking for the current calendar month
/// - [weekly] — ranking for the current calendar week
enum LeaderboardPeriod { allTime, monthly, weekly }
