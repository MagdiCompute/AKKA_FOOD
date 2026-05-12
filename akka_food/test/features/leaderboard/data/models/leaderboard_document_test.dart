import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/leaderboard/data/models/leaderboard_document.dart';

void main() {
  // ---------------------------------------------------------------------------
  // LeaderboardDocument.fromMap — basic deserialization
  // ---------------------------------------------------------------------------

  group('LeaderboardDocument.fromMap — basic deserialization', () {
    test('parses entries array with correct rank assignment', () {
      final map = <String, dynamic>{
        'entries': [
          {'uid': 'user1', 'displayName': 'Alice', 'avatarUrl': 'https://img.com/a.png', 'score': 50},
          {'uid': 'user2', 'displayName': 'Bob', 'avatarUrl': null, 'score': 30},
          {'uid': 'user3', 'displayName': 'Charlie', 'avatarUrl': 'https://img.com/c.png', 'score': 10},
        ],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 6, 15, 12, 0, 0)),
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.entries.length, equals(3));
      expect(doc.entries[0].rank, equals(1));
      expect(doc.entries[0].uid, equals('user1'));
      expect(doc.entries[0].displayName, equals('Alice'));
      expect(doc.entries[0].avatarUrl, equals('https://img.com/a.png'));
      expect(doc.entries[0].score, equals(50));
      expect(doc.entries[1].rank, equals(2));
      expect(doc.entries[1].uid, equals('user2'));
      expect(doc.entries[1].displayName, equals('Bob'));
      expect(doc.entries[1].avatarUrl, isNull);
      expect(doc.entries[1].score, equals(30));
      expect(doc.entries[2].rank, equals(3));
      expect(doc.entries[2].uid, equals('user3'));
      expect(doc.entries[2].score, equals(10));
    });

    test('parses updatedAt from Firestore Timestamp', () {
      final expectedDate = DateTime(2024, 6, 15, 12, 0, 0);
      final map = <String, dynamic>{
        'entries': <dynamic>[],
        'updatedAt': Timestamp.fromDate(expectedDate),
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.updatedAt, equals(expectedDate));
    });

    test('parses updatedAt from int (milliseconds since epoch)', () {
      final expectedDate = DateTime(2024, 6, 15, 12, 0, 0);
      final map = <String, dynamic>{
        'entries': <dynamic>[],
        'updatedAt': expectedDate.millisecondsSinceEpoch,
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.updatedAt, equals(expectedDate));
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardDocument.fromMap — currentUid matching
  // ---------------------------------------------------------------------------

  group('LeaderboardDocument.fromMap — currentUid matching', () {
    test('marks matching entry as isCurrentUser when currentUid provided', () {
      final map = <String, dynamic>{
        'entries': [
          {'uid': 'user1', 'displayName': 'Alice', 'score': 50},
          {'uid': 'user2', 'displayName': 'Bob', 'score': 30},
        ],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final doc = LeaderboardDocument.fromMap(map, currentUid: 'user2');

      expect(doc.entries[0].isCurrentUser, isFalse);
      expect(doc.entries[1].isCurrentUser, isTrue);
    });

    test('no entry marked when currentUid is null', () {
      final map = <String, dynamic>{
        'entries': [
          {'uid': 'user1', 'displayName': 'Alice', 'score': 50},
        ],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.entries[0].isCurrentUser, isFalse);
    });

    test('no entry marked when currentUid does not match any entry', () {
      final map = <String, dynamic>{
        'entries': [
          {'uid': 'user1', 'displayName': 'Alice', 'score': 50},
        ],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final doc = LeaderboardDocument.fromMap(map, currentUid: 'unknown');

      expect(doc.entries[0].isCurrentUser, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardDocument.fromMap — edge cases
  // ---------------------------------------------------------------------------

  group('LeaderboardDocument.fromMap — edge cases', () {
    test('handles empty entries array', () {
      final map = <String, dynamic>{
        'entries': <dynamic>[],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.entries, isEmpty);
    });

    test('handles null entries field', () {
      final map = <String, dynamic>{
        'entries': null,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.entries, isEmpty);
    });

    test('handles missing entries field', () {
      final map = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.entries, isEmpty);
    });

    test('handles null updatedAt with fallback to DateTime.now()', () {
      final before = DateTime.now();
      final map = <String, dynamic>{
        'entries': <dynamic>[],
        'updatedAt': null,
      };

      final doc = LeaderboardDocument.fromMap(map);
      final after = DateTime.now();

      expect(doc.updatedAt.isAfter(before) || doc.updatedAt.isAtSameMomentAs(before), isTrue);
      expect(doc.updatedAt.isBefore(after) || doc.updatedAt.isAtSameMomentAs(after), isTrue);
    });

    test('handles entry with missing displayName defaults to empty string', () {
      final map = <String, dynamic>{
        'entries': [
          {'uid': 'user1', 'score': 10},
        ],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.entries[0].displayName, equals(''));
    });

    test('handles entry with null score defaults to 0', () {
      final map = <String, dynamic>{
        'entries': [
          {'uid': 'user1', 'displayName': 'Alice', 'score': null},
        ],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      };

      final doc = LeaderboardDocument.fromMap(map);

      expect(doc.entries[0].score, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardDocument.toMap — serialization
  // ---------------------------------------------------------------------------

  group('LeaderboardDocument.toMap — serialization', () {
    test('serializes entries with only Firestore-stored fields', () {
      final doc = LeaderboardDocument.fromMap(<String, dynamic>{
        'entries': [
          {'uid': 'user1', 'displayName': 'Alice', 'avatarUrl': 'https://img.com/a.png', 'score': 50},
          {'uid': 'user2', 'displayName': 'Bob', 'avatarUrl': null, 'score': 30},
        ],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 6, 15, 12, 0, 0)),
      });

      final map = doc.toMap();

      final entries = map['entries'] as List<Map<String, dynamic>>;
      expect(entries.length, equals(2));
      expect(entries[0], equals({'uid': 'user1', 'displayName': 'Alice', 'avatarUrl': 'https://img.com/a.png', 'score': 50}));
      expect(entries[1], equals({'uid': 'user2', 'displayName': 'Bob', 'avatarUrl': null, 'score': 30}));

      // Should NOT include rank or isCurrentUser in serialized output
      expect(entries[0].containsKey('rank'), isFalse);
      expect(entries[0].containsKey('isCurrentUser'), isFalse);
    });

    test('serializes updatedAt as Firestore Timestamp', () {
      final date = DateTime(2024, 6, 15, 12, 0, 0);
      final doc = LeaderboardDocument.fromMap(<String, dynamic>{
        'entries': <dynamic>[],
        'updatedAt': Timestamp.fromDate(date),
      });

      final map = doc.toMap();

      expect(map['updatedAt'], isA<Timestamp>());
      expect((map['updatedAt'] as Timestamp).toDate(), equals(date));
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardDocument — round-trip serialization
  // ---------------------------------------------------------------------------

  group('LeaderboardDocument — round-trip serialization', () {
    test('fromMap → toMap → fromMap produces equivalent entries', () {
      final originalMap = <String, dynamic>{
        'entries': [
          {'uid': 'user1', 'displayName': 'Alice', 'avatarUrl': 'https://img.com/a.png', 'score': 50},
          {'uid': 'user2', 'displayName': 'Bob', 'avatarUrl': null, 'score': 30},
          {'uid': 'user3', 'displayName': 'Charlie', 'avatarUrl': 'https://img.com/c.png', 'score': 10},
        ],
        'updatedAt': Timestamp.fromDate(DateTime(2024, 6, 15, 12, 0, 0)),
      };

      final doc1 = LeaderboardDocument.fromMap(originalMap);
      final serialized = doc1.toMap();
      final doc2 = LeaderboardDocument.fromMap(serialized);

      expect(doc2.entries.length, equals(doc1.entries.length));
      for (var i = 0; i < doc1.entries.length; i++) {
        expect(doc2.entries[i].uid, equals(doc1.entries[i].uid));
        expect(doc2.entries[i].displayName, equals(doc1.entries[i].displayName));
        expect(doc2.entries[i].avatarUrl, equals(doc1.entries[i].avatarUrl));
        expect(doc2.entries[i].score, equals(doc1.entries[i].score));
        expect(doc2.entries[i].rank, equals(doc1.entries[i].rank));
      }
      expect(doc2.updatedAt, equals(doc1.updatedAt));
    });
  });
}
