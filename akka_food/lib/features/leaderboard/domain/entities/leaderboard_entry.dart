import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_entry.freezed.dart';

/// Domain entity representing a single row on the leaderboard.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// [rank] is the user's position on the leaderboard (1 = highest).
/// [uid] is the unique user identifier.
/// [displayName] is the user's visible name on the leaderboard.
/// [avatarUrl] is an optional URL to the user's avatar image.
/// [score] is the total number of completed orders for the period.
/// [isCurrentUser] indicates whether this entry belongs to the authenticated user.
///
/// Used across all period views (all-time, monthly, weekly).
///
/// Firestore serialization is handled manually via [fromMap] / [toMap]
/// so the domain layer stays free of Firebase dependencies.
@freezed
abstract class LeaderboardEntry with _$LeaderboardEntry {
  const LeaderboardEntry._();

  const factory LeaderboardEntry({
    required int rank,
    required String uid,
    required String displayName,
    String? avatarUrl,
    required int score,
    @Default(false) bool isCurrentUser,
  }) = _LeaderboardEntry;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, {int rank = 0, bool isCurrentUser = false}) {
    return LeaderboardEntry(
      rank: map['rank'] as int? ?? rank,
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      score: map['score'] as int,
      isCurrentUser: map['isCurrentUser'] as bool? ?? isCurrentUser,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rank': rank,
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'score': score,
      'isCurrentUser': isCurrentUser,
    };
  }
}
