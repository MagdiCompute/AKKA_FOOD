import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/leaderboard/data/models/user_score.dart';

void main() {
  // ---------------------------------------------------------------------------
  // UserScore — constructor defaults
  // ---------------------------------------------------------------------------

  group('UserScore — constructor defaults', () {
    test('leaderboardVisible defaults to true', () {
      const score = UserScore(
        allTimeScore: 10,
        monthlyScore: 5,
        weeklyScore: 2,
      );

      expect(score.leaderboardVisible, isTrue);
    });

    test('const constructor creates immutable instance', () {
      const score = UserScore(
        allTimeScore: 0,
        monthlyScore: 0,
        weeklyScore: 0,
        leaderboardVisible: false,
      );

      expect(score.allTimeScore, equals(0));
      expect(score.monthlyScore, equals(0));
      expect(score.weeklyScore, equals(0));
      expect(score.leaderboardVisible, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // UserScore.fromMap — deserialization
  // ---------------------------------------------------------------------------

  group('UserScore.fromMap — deserialization', () {
    test('parses all fields correctly', () {
      final map = <String, dynamic>{
        'allTimeScore': 42,
        'monthlyScore': 10,
        'weeklyScore': 3,
        'leaderboardVisible': false,
      };

      final score = UserScore.fromMap(map);

      expect(score.allTimeScore, equals(42));
      expect(score.monthlyScore, equals(10));
      expect(score.weeklyScore, equals(3));
      expect(score.leaderboardVisible, isFalse);
    });

    test('handles null numeric fields with default 0', () {
      final map = <String, dynamic>{
        'allTimeScore': null,
        'monthlyScore': null,
        'weeklyScore': null,
        'leaderboardVisible': true,
      };

      final score = UserScore.fromMap(map);

      expect(score.allTimeScore, equals(0));
      expect(score.monthlyScore, equals(0));
      expect(score.weeklyScore, equals(0));
    });

    test('handles missing fields with defaults', () {
      final map = <String, dynamic>{};

      final score = UserScore.fromMap(map);

      expect(score.allTimeScore, equals(0));
      expect(score.monthlyScore, equals(0));
      expect(score.weeklyScore, equals(0));
      expect(score.leaderboardVisible, isTrue);
    });

    test('handles null leaderboardVisible with default true', () {
      final map = <String, dynamic>{
        'allTimeScore': 5,
        'monthlyScore': 2,
        'weeklyScore': 1,
        'leaderboardVisible': null,
      };

      final score = UserScore.fromMap(map);

      expect(score.leaderboardVisible, isTrue);
    });

    test('handles double values by converting to int', () {
      final map = <String, dynamic>{
        'allTimeScore': 42.0,
        'monthlyScore': 10.5,
        'weeklyScore': 3.9,
        'leaderboardVisible': true,
      };

      final score = UserScore.fromMap(map);

      expect(score.allTimeScore, equals(42));
      expect(score.monthlyScore, equals(10));
      expect(score.weeklyScore, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  // UserScore.toMap — serialization
  // ---------------------------------------------------------------------------

  group('UserScore.toMap — serialization', () {
    test('serializes all fields correctly', () {
      const score = UserScore(
        allTimeScore: 42,
        monthlyScore: 10,
        weeklyScore: 3,
        leaderboardVisible: false,
      );

      final map = score.toMap();

      expect(map['allTimeScore'], equals(42));
      expect(map['monthlyScore'], equals(10));
      expect(map['weeklyScore'], equals(3));
      expect(map['leaderboardVisible'], isFalse);
    });

    test('serializes default leaderboardVisible as true', () {
      const score = UserScore(
        allTimeScore: 0,
        monthlyScore: 0,
        weeklyScore: 0,
      );

      final map = score.toMap();

      expect(map['leaderboardVisible'], isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // UserScore — round-trip serialization
  // ---------------------------------------------------------------------------

  group('UserScore — round-trip serialization', () {
    test('fromMap → toMap → fromMap produces equal instance', () {
      final originalMap = <String, dynamic>{
        'allTimeScore': 100,
        'monthlyScore': 25,
        'weeklyScore': 7,
        'leaderboardVisible': false,
      };

      final score1 = UserScore.fromMap(originalMap);
      final serialized = score1.toMap();
      final score2 = UserScore.fromMap(serialized);

      expect(score2, equals(score1));
    });
  });

  // ---------------------------------------------------------------------------
  // UserScore.copyWith
  // ---------------------------------------------------------------------------

  group('UserScore.copyWith', () {
    test('returns identical instance when no fields changed', () {
      const original = UserScore(
        allTimeScore: 42,
        monthlyScore: 10,
        weeklyScore: 3,
        leaderboardVisible: true,
      );

      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('updates only specified fields', () {
      const original = UserScore(
        allTimeScore: 42,
        monthlyScore: 10,
        weeklyScore: 3,
        leaderboardVisible: true,
      );

      final copy = original.copyWith(weeklyScore: 0, leaderboardVisible: false);

      expect(copy.allTimeScore, equals(42));
      expect(copy.monthlyScore, equals(10));
      expect(copy.weeklyScore, equals(0));
      expect(copy.leaderboardVisible, isFalse);
    });

    test('updates allTimeScore independently', () {
      const original = UserScore(
        allTimeScore: 10,
        monthlyScore: 5,
        weeklyScore: 2,
      );

      final copy = original.copyWith(allTimeScore: 11);

      expect(copy.allTimeScore, equals(11));
      expect(copy.monthlyScore, equals(5));
      expect(copy.weeklyScore, equals(2));
      expect(copy.leaderboardVisible, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // UserScore — equality
  // ---------------------------------------------------------------------------

  group('UserScore — equality', () {
    test('two instances with same values are equal', () {
      const a = UserScore(
        allTimeScore: 42,
        monthlyScore: 10,
        weeklyScore: 3,
        leaderboardVisible: true,
      );
      const b = UserScore(
        allTimeScore: 42,
        monthlyScore: 10,
        weeklyScore: 3,
        leaderboardVisible: true,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different allTimeScore are not equal', () {
      const a = UserScore(allTimeScore: 42, monthlyScore: 10, weeklyScore: 3);
      const b = UserScore(allTimeScore: 43, monthlyScore: 10, weeklyScore: 3);

      expect(a, isNot(equals(b)));
    });

    test('instances with different leaderboardVisible are not equal', () {
      const a = UserScore(
        allTimeScore: 42,
        monthlyScore: 10,
        weeklyScore: 3,
        leaderboardVisible: true,
      );
      const b = UserScore(
        allTimeScore: 42,
        monthlyScore: 10,
        weeklyScore: 3,
        leaderboardVisible: false,
      );

      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // UserScore — toString
  // ---------------------------------------------------------------------------

  group('UserScore — toString', () {
    test('produces readable string representation', () {
      const score = UserScore(
        allTimeScore: 42,
        monthlyScore: 10,
        weeklyScore: 3,
        leaderboardVisible: true,
      );

      expect(
        score.toString(),
        equals(
          'UserScore(allTimeScore: 42, monthlyScore: 10, weeklyScore: 3, leaderboardVisible: true)',
        ),
      );
    });
  });
}
