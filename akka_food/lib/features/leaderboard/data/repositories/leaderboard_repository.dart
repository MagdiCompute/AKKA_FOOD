import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../../domain/repositories/i_leaderboard_repository.dart';
import '../datasources/firestore_leaderboard_data_source.dart';

/// Concrete implementation of [ILeaderboardRepository].
///
/// Bridges the data layer ([FirestoreLeaderboardDataSource]) to the domain
/// layer by mapping data source results to domain entities.
///
/// Accepts [FirestoreLeaderboardDataSource] and [FirebaseAuth] via constructor
/// for dependency injection and testability.
class LeaderboardRepository implements ILeaderboardRepository {
  LeaderboardRepository({
    required FirestoreLeaderboardDataSource dataSource,
    FirebaseAuth? firebaseAuth,
  })  : _dataSource = dataSource,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirestoreLeaderboardDataSource _dataSource;
  final FirebaseAuth _firebaseAuth;

  /// Returns the current authenticated user's UID, or `null` if not signed in.
  String? get _currentUid => _firebaseAuth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // ILeaderboardRepository — real-time stream
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of the top 100 [LeaderboardEntry] items
  /// for the given [period].
  ///
  /// Extracts entries from the [LeaderboardDocument] emitted by the data
  /// source. The current user's entry is flagged with `isCurrentUser: true`.
  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard(LeaderboardPeriod period) {
    return _dataSource
        .watchLeaderboard(period, currentUid: _currentUid)
        .map((document) => document.entries);
  }

  // ---------------------------------------------------------------------------
  // ILeaderboardRepository — one-shot fetch
  // ---------------------------------------------------------------------------

  /// Returns a one-time fetch of the top 100 [LeaderboardEntry] items
  /// for the given [period].
  ///
  /// Uses the real-time stream internally and takes the first emission.
  @override
  Future<List<LeaderboardEntry>> getLeaderboard(LeaderboardPeriod period) {
    return _dataSource
        .watchLeaderboard(period, currentUid: _currentUid)
        .map((document) => document.entries)
        .first;
  }

  // ---------------------------------------------------------------------------
  // ILeaderboardRepository — current user entry
  // ---------------------------------------------------------------------------

  /// Returns the current authenticated user's [LeaderboardEntry] for the
  /// given [period], including their rank and score.
  ///
  /// Strategy:
  /// 1. Check if the user is in the top 100 entries (from the leaderboard
  ///    document).
  /// 2. If not found, call [FirestoreLeaderboardDataSource.getCurrentUserRank]
  ///    to compute their rank via a Firestore count query.
  ///
  /// Returns `null` if no user is signed in or the user has no score data.
  @override
  Future<LeaderboardEntry?> getCurrentUserEntry(
    LeaderboardPeriod period,
  ) async {
    final uid = _currentUid;
    if (uid == null) return null;

    try {
      // 1. Fetch the leaderboard document and check if user is in top 100.
      final document = await _dataSource
          .watchLeaderboard(period, currentUid: uid)
          .first;

      final topEntry = document.entries.cast<LeaderboardEntry?>().firstWhere(
            (entry) => entry!.uid == uid,
            orElse: () => null,
          );

      if (topEntry != null) {
        return topEntry;
      }

      // 2. User not in top 100 — compute rank via data source.
      return await _dataSource.getCurrentUserRank(uid, period);
    } catch (_) {
      // Handle errors gracefully — return null if anything fails.
      return null;
    }
  }
}
