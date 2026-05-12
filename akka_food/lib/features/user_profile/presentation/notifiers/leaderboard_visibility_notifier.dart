import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../../leaderboard/data/leaderboard_paths.dart';

part 'leaderboard_visibility_notifier.g.dart';

// ---------------------------------------------------------------------------
// LeaderboardVisibilityNotifier
// ---------------------------------------------------------------------------

/// Manages the `leaderboardVisible` toggle state for the current user.
///
/// Reads and writes directly to `/userScores/{uid}.leaderboardVisible` in
/// Firestore. This is separate from the notification preferences because
/// leaderboard visibility lives in a different collection.
///
/// Returns `null` when no user is signed in.
/// Defaults to `true` (opted in) when the document does not exist.
///
/// Satisfies Requirement 4 AC1.
@riverpod
class LeaderboardVisibilityNotifier extends _$LeaderboardVisibilityNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // build — load current visibility
  // ---------------------------------------------------------------------------

  /// Loads the current `leaderboardVisible` value from Firestore.
  ///
  /// Returns `true` (default) if the document does not exist or the field is
  /// missing.
  /// Returns `null` when no user is signed in.
  @override
  Future<bool?> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return null;

    final path = LeaderboardPaths.userScorePath(currentUser.uid);
    final parts = path.split('/');
    final collection = parts[0];
    final docId = parts[1];

    final snapshot =
        await _firestore.collection(collection).doc(docId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return true; // default: opted in
    }

    return snapshot.data()!['leaderboardVisible'] as bool? ?? true;
  }

  // ---------------------------------------------------------------------------
  // toggle
  // ---------------------------------------------------------------------------

  /// Updates the `leaderboardVisible` field in `/userScores/{uid}`.
  ///
  /// Uses `set` with `merge: true` so that the document is created if it
  /// doesn't exist yet.
  ///
  /// Preserves the previous state on error.
  Future<void> toggle(bool value) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError(
          'Cannot update leaderboard visibility: no authenticated user.');
    }

    final previous = state;
    state = const AsyncLoading<bool?>().copyWithPrevious(previous);

    try {
      final path = LeaderboardPaths.userScorePath(currentUser.uid);
      final parts = path.split('/');
      final collection = parts[0];
      final docId = parts[1];

      await _firestore.collection(collection).doc(docId).set(
        {'leaderboardVisible': value},
        SetOptions(merge: true),
      );

      state = AsyncData<bool?>(value);
    } catch (e, st) {
      state = AsyncError<bool?>(e, st).copyWithPrevious(previous);
    }
  }
}
