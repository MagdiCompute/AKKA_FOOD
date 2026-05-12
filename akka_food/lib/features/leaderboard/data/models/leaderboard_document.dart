import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/leaderboard_entry.dart';

/// Data-layer model representing a Firestore `/leaderboard/{period}` document.
///
/// Firestore structure:
/// ```
/// /leaderboard/all_time
///   - entries: [{ uid, displayName, avatarUrl, score }]  // sorted by score desc, top 100
///   - updatedAt: timestamp
/// ```
///
/// This class handles serialization between Firestore maps and domain
/// [LeaderboardEntry] entities. The [entries] array stores raw entry data
/// without rank — rank is derived from array index (position + 1).
class LeaderboardDocument {
  const LeaderboardDocument({
    required this.entries,
    required this.updatedAt,
  });

  /// Top 100 leaderboard entries sorted by score descending.
  final List<LeaderboardEntry> entries;

  /// Timestamp of the last leaderboard rebuild.
  final DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  /// Creates a [LeaderboardDocument] from a Firestore document snapshot map.
  ///
  /// Each entry in the `entries` array is deserialized into a [LeaderboardEntry]
  /// with rank derived from its position in the array (1-indexed).
  ///
  /// [currentUid] is optional — when provided, the matching entry will have
  /// [LeaderboardEntry.isCurrentUser] set to `true`.
  factory LeaderboardDocument.fromMap(
    Map<String, dynamic> map, {
    String? currentUid,
  }) {
    final rawEntries = (map['entries'] as List<dynamic>?) ?? <dynamic>[];

    final entries = rawEntries.asMap().entries.map((indexed) {
      final index = indexed.key;
      final data = indexed.value as Map<String, dynamic>;
      final uid = data['uid'] as String;

      return LeaderboardEntry(
        rank: index + 1,
        uid: uid,
        displayName: data['displayName'] as String? ?? '',
        avatarUrl: data['avatarUrl'] as String?,
        score: (data['score'] as num?)?.toInt() ?? 0,
        isCurrentUser: currentUid != null && uid == currentUid,
      );
    }).toList();

    final updatedAt = _parseDateTime(map['updatedAt']);

    return LeaderboardDocument(
      entries: entries,
      updatedAt: updatedAt,
    );
  }

  /// Serializes this document to a Firestore-compatible map.
  ///
  /// The `entries` array contains only the fields stored in Firestore
  /// (uid, displayName, avatarUrl, score) — rank and isCurrentUser are
  /// derived at read time.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'entries': entries.map((entry) => <String, dynamic>{
        'uid': entry.uid,
        'displayName': entry.displayName,
        'avatarUrl': entry.avatarUrl,
        'score': entry.score,
      }).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses a Firestore timestamp field into a [DateTime].
  ///
  /// Handles [Timestamp], [int] (milliseconds since epoch), and `null`.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
