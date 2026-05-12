import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/leaderboard/data/datasources/firestore_leaderboard_data_source.dart';
import 'package:akka_food/features/leaderboard/domain/entities/leaderboard_period.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreLeaderboardDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreLeaderboardDataSource(firestore: fakeFirestore);
  });

  group('getCurrentUserRank', () {
    const testUid = 'user_123';

    Future<void> seedUserScore(
      String uid, {
      int allTimeScore = 0,
      int monthlyScore = 0,
      int weeklyScore = 0,
      bool leaderboardVisible = true,
    }) async {
      await fakeFirestore.collection('userScores').doc(uid).set({
        'allTimeScore': allTimeScore,
        'monthlyScore': monthlyScore,
        'weeklyScore': weeklyScore,
        'leaderboardVisible': leaderboardVisible,
      });
    }

    Future<void> seedUserProfile(
      String uid, {
      String displayName = 'Test User',
      String? avatarUrl,
    }) async {
      await fakeFirestore.collection('users').doc(uid).set({
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
    }

    test('returns null when user score document does not exist', () async {
      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.allTime,
      );

      expect(result, isNull);
    });

    test('returns null when user has opted out (leaderboardVisible == false)',
        () async {
      await seedUserScore(testUid, allTimeScore: 50, leaderboardVisible: false);

      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.allTime,
      );

      expect(result, isNull);
    });

    test('returns rank 1 when no other users have a higher score', () async {
      await seedUserScore(testUid, allTimeScore: 100);
      await seedUserProfile(testUid, displayName: 'Top User');

      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.allTime,
      );

      expect(result, isNotNull);
      expect(result!.rank, 1);
      expect(result.uid, testUid);
      expect(result.displayName, 'Top User');
      expect(result.score, 100);
      expect(result.isCurrentUser, true);
    });

    test('computes correct rank based on users with higher scores', () async {
      // Seed 3 users with higher scores
      await seedUserScore('user_a', allTimeScore: 200);
      await seedUserScore('user_b', allTimeScore: 150);
      await seedUserScore('user_c', allTimeScore: 120);
      // Current user has score 100 → rank should be 4
      await seedUserScore(testUid, allTimeScore: 100);
      await seedUserProfile(testUid, displayName: 'Current User');

      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.allTime,
      );

      expect(result, isNotNull);
      expect(result!.rank, 4);
      expect(result.score, 100);
      expect(result.isCurrentUser, true);
    });

    test('excludes opted-out users from rank calculation', () async {
      // user_a is visible with higher score
      await seedUserScore('user_a', allTimeScore: 200);
      // user_b opted out with higher score — should not count
      await seedUserScore('user_b',
          allTimeScore: 150, leaderboardVisible: false);
      // Current user
      await seedUserScore(testUid, allTimeScore: 100);
      await seedUserProfile(testUid, displayName: 'Current User');

      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.allTime,
      );

      // Only user_a counts → rank = 2
      expect(result, isNotNull);
      expect(result!.rank, 2);
    });

    test('uses monthlyScore for monthly period', () async {
      await seedUserScore('user_a', monthlyScore: 30);
      await seedUserScore('user_b', monthlyScore: 20);
      await seedUserScore(testUid, monthlyScore: 10);
      await seedUserProfile(testUid, displayName: 'Monthly User');

      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.monthly,
      );

      expect(result, isNotNull);
      expect(result!.rank, 3);
      expect(result.score, 10);
    });

    test('uses weeklyScore for weekly period', () async {
      await seedUserScore('user_a', weeklyScore: 15);
      await seedUserScore(testUid, weeklyScore: 5);
      await seedUserProfile(testUid, displayName: 'Weekly User');

      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.weekly,
      );

      expect(result, isNotNull);
      expect(result!.rank, 2);
      expect(result.score, 5);
    });

    test('fetches avatarUrl from user profile', () async {
      await seedUserScore(testUid, allTimeScore: 50);
      await seedUserProfile(
        testUid,
        displayName: 'Avatar User',
        avatarUrl: 'https://example.com/avatar.png',
      );

      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.allTime,
      );

      expect(result, isNotNull);
      expect(result!.avatarUrl, 'https://example.com/avatar.png');
    });

    test('returns "Unknown" displayName when user profile does not exist',
        () async {
      await seedUserScore(testUid, allTimeScore: 50);
      // No user profile seeded

      final result = await dataSource.getCurrentUserRank(
        testUid,
        LeaderboardPeriod.allTime,
      );

      expect(result, isNotNull);
      expect(result!.displayName, 'Unknown');
    });
  });
}
