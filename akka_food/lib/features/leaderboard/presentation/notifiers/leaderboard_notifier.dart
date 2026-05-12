import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/firestore_leaderboard_data_source.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../../domain/repositories/i_leaderboard_repository.dart';

part 'leaderboard_notifier.g.dart';

// ---------------------------------------------------------------------------
// Data source provider
// ---------------------------------------------------------------------------

/// Provides the [FirestoreLeaderboardDataSource] wired to the default
/// [FirebaseFirestore] instance.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
FirestoreLeaderboardDataSource firestoreLeaderboardDataSource(Ref ref) {
  return FirestoreLeaderboardDataSource(
    firestore: FirebaseFirestore.instance,
  );
}

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [LeaderboardRepository] bound to
/// [ILeaderboardRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreLeaderboardDataSource] — real-time leaderboard streams and
///   user rank computation from Firestore.
/// - [FirebaseAuth] — current user identification.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
ILeaderboardRepository leaderboardRepository(Ref ref) {
  return LeaderboardRepository(
    dataSource: ref.watch(firestoreLeaderboardDataSourceProvider),
    firebaseAuth: FirebaseAuth.instance,
  );
}

// ---------------------------------------------------------------------------
// Leaderboard Stream Provider (real-time)
// ---------------------------------------------------------------------------

/// A family [StreamProvider] that exposes a real-time stream of
/// [LeaderboardEntry] items for the given [period].
///
/// Uses [ILeaderboardRepository.watchLeaderboard] to subscribe to Firestore
/// `snapshots()` on the leaderboard document. The stream emits a new list
/// whenever the document changes (e.g., after a new order is completed and
/// the Cloud Function rebuilds the leaderboard).
///
/// When the user switches period tabs, Riverpod automatically disposes the
/// previous period's provider (cancelling the Firestore listener) and creates
/// a new one for the selected period.
///
/// Satisfies:
/// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
/// - Requirement 1 AC5: Rankings update within 60 seconds of a new completed
///   order (real-time listener handles this).
@riverpod
Stream<List<LeaderboardEntry>> leaderboardStream(
  Ref ref,
  LeaderboardPeriod period,
) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.watchLeaderboard(period);
}

// ---------------------------------------------------------------------------
// LeaderboardNotifier
// ---------------------------------------------------------------------------

/// Manages the leaderboard state for the Leaderboard feature.
///
/// Responsibilities:
/// - Fetching the top 100 leaderboard entries for a given [LeaderboardPeriod].
/// - Tracking the currently selected period via [_period].
/// - Providing the current user's [LeaderboardEntry] (whether in top 100 or
///   computed rank outside top 100).
/// - Handling loading/error states via [AsyncValue].
///
/// Satisfies:
/// - Requirement 1 AC1: Return top 100 entries ranked by score descending.
/// - Requirement 1 AC3: Support three period tabs (All-Time, Monthly, Weekly).
/// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
/// - Requirement 2 AC2: Display user's rank when outside top 100.
@riverpod
class LeaderboardNotifier extends _$LeaderboardNotifier {
  LeaderboardPeriod _period = LeaderboardPeriod.allTime;

  // ---------------------------------------------------------------------------
  // build — initial load
  // ---------------------------------------------------------------------------

  /// Initialises the notifier by fetching the leaderboard for the default
  /// period ([LeaderboardPeriod.allTime]).
  ///
  /// Returns an empty list if the leaderboard document does not exist yet.
  @override
  Future<List<LeaderboardEntry>> build() async {
    _period = LeaderboardPeriod.allTime;
    return _fetchLeaderboard(_period);
  }

  // ---------------------------------------------------------------------------
  // Convenience accessor
  // ---------------------------------------------------------------------------

  /// The repository instance provided by [leaderboardRepositoryProvider].
  ILeaderboardRepository get _repository =>
      ref.read(leaderboardRepositoryProvider);

  /// The currently active leaderboard period.
  LeaderboardPeriod get currentPeriod => _period;

  // ---------------------------------------------------------------------------
  // loadLeaderboard
  // ---------------------------------------------------------------------------

  /// Fetches the leaderboard for the given [period] and updates state.
  ///
  /// Sets the state to [AsyncLoading] (preserving previous data) while the
  /// request is in flight. On success, updates state with the new entries.
  /// On failure, sets an [AsyncError] state while preserving previous data.
  ///
  /// Also updates [_period] to the new period.
  Future<void> loadLeaderboard(LeaderboardPeriod period) async {
    _period = period;

    final previous = state;
    state = const AsyncLoading<List<LeaderboardEntry>>()
        .copyWithPrevious(previous);

    try {
      final entries = await _fetchLeaderboard(period);
      state = AsyncData(entries);
    } catch (e, st) {
      state = AsyncError<List<LeaderboardEntry>>(e, st)
          .copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // getCurrentUserEntry
  // ---------------------------------------------------------------------------

  /// Returns the current user's [LeaderboardEntry] for the given [period].
  ///
  /// The entry includes the user's rank and score. Works for users both inside
  /// and outside the top 100:
  /// - If the user is in the top 100, their entry is extracted from the
  ///   leaderboard document.
  /// - If the user is outside the top 100, their rank is computed via a
  ///   Firestore count query.
  ///
  /// Returns `null` if no user is signed in or the user has no score data.
  Future<LeaderboardEntry?> getCurrentUserEntry(
    LeaderboardPeriod period,
  ) async {
    try {
      return await _repository.getCurrentUserEntry(period);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // refresh
  // ---------------------------------------------------------------------------

  /// Reloads the leaderboard for the current period from scratch.
  ///
  /// Triggers a full rebuild of the notifier via [ref.invalidateSelf].
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Fetches the leaderboard entries for [period] from the repository.
  Future<List<LeaderboardEntry>> _fetchLeaderboard(
    LeaderboardPeriod period,
  ) async {
    return _repository.getLeaderboard(period);
  }
}
