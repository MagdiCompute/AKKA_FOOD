import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../leaderboard_paths.dart';
import '../models/leaderboard_document.dart';
import '../models/user_score.dart';

/// Remote data source that provides real-time streams and one-shot reads
/// from Firestore for leaderboard and user score documents.
///
/// Uses Firestore `snapshots()` listeners to keep rankings live.
///
/// Accepts [FirebaseFirestore] via constructor for testability.
class FirestoreLeaderboardDataSource {
  FirestoreLeaderboardDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Leaderboard document
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of the [LeaderboardDocument] for the given
  /// [period].
  ///
  /// Uses Firestore `snapshots()` to emit a new value whenever the document
  /// changes. If the document does not exist, emits an empty
  /// [LeaderboardDocument] with no entries and the current timestamp.
  ///
  /// [currentUid] is forwarded to [LeaderboardDocument.fromMap] so the
  /// matching entry can be flagged with `isCurrentUser = true`.
  Stream<LeaderboardDocument> watchLeaderboard(
    LeaderboardPeriod period, {
    String? currentUid,
  }) {
    final path = LeaderboardPaths.documentPath(period);
    final parts = path.split('/');
    final collection = parts[0];
    final docId = parts[1];

    return _firestore
        .collection(collection)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return LeaderboardDocument(
          entries: [],
          updatedAt: DateTime.now(),
        );
      }
      return LeaderboardDocument.fromMap(
        snapshot.data()!,
        currentUid: currentUid,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // User score — one-shot
  // ---------------------------------------------------------------------------

  /// Fetches the user's score document from `/userScores/{uid}`.
  ///
  /// Returns `null` if the document does not exist.
  Future<UserScore?> getUserScore(String uid) async {
    final path = LeaderboardPaths.userScorePath(uid);
    final parts = path.split('/');
    final collection = parts[0];
    final docId = parts[1];

    final snapshot =
        await _firestore.collection(collection).doc(docId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return UserScore.fromMap(snapshot.data()!);
  }

  // ---------------------------------------------------------------------------
  // User score — real-time
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of the user's score document at
  /// `/userScores/{uid}`.
  ///
  /// Emits `null` if the document does not exist.
  Stream<UserScore?> watchUserScore(String uid) {
    final path = LeaderboardPaths.userScorePath(uid);
    final parts = path.split('/');
    final collection = parts[0];
    final docId = parts[1];

    return _firestore
        .collection(collection)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserScore.fromMap(snapshot.data()!);
    });
  }

  // ---------------------------------------------------------------------------
  // Current user rank (outside top 100)
  // ---------------------------------------------------------------------------

  /// Computes the current user's rank when they are not in the top 100.
  ///
  /// Steps:
  /// 1. Fetch `/userScores/{uid}` for the user's score.
  /// 2. If the document doesn't exist or `leaderboardVisible == false`, return `null`.
  /// 3. Determine the score field based on [period].
  /// 4. Count all visible users with a higher score.
  /// 5. Rank = count + 1.
  /// 6. Fetch display name and avatar from `/users/{uid}`.
  /// 7. Return a [LeaderboardEntry] with `isCurrentUser: true`.
  ///
  /// Returns `null` if the user has no score document or has opted out.
  Future<LeaderboardEntry?> getCurrentUserRank(
    String uid,
    LeaderboardPeriod period,
  ) async {
    // 1. Fetch the user's score document.
    final userScore = await getUserScore(uid);

    // 2. If no document or user opted out, return null.
    if (userScore == null || !userScore.leaderboardVisible) {
      return null;
    }

    // 3. Determine the score field name and value based on period.
    final String scoreField;
    final int currentScore;
    switch (period) {
      case LeaderboardPeriod.allTime:
        scoreField = 'allTimeScore';
        currentScore = userScore.allTimeScore;
      case LeaderboardPeriod.monthly:
        scoreField = 'monthlyScore';
        currentScore = userScore.monthlyScore;
      case LeaderboardPeriod.weekly:
        scoreField = 'weeklyScore';
        currentScore = userScore.weeklyScore;
    }

    // 4. Count visible users with a higher score.
    final querySnapshot = await _firestore
        .collection(LeaderboardPaths.userScoresCollection)
        .where('leaderboardVisible', isEqualTo: true)
        .where(scoreField, isGreaterThan: currentScore)
        .count()
        .get();

    final count = querySnapshot.count ?? 0;

    // 5. Rank = count + 1.
    final rank = count + 1;

    // 6. Fetch display name and avatar from /users/{uid}.
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();
    final displayName = userData?['displayName'] as String? ??
        userData?['name'] as String? ??
        'Unknown';
    final avatarUrl = userData?['avatarUrl'] as String? ??
        userData?['photoUrl'] as String?;

    // 7. Return a LeaderboardEntry.
    return LeaderboardEntry(
      rank: rank,
      uid: uid,
      displayName: displayName,
      avatarUrl: avatarUrl,
      score: currentScore,
      isCurrentUser: true,
    );
  }
}
