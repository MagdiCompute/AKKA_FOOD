import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/leaderboard/data/leaderboard_paths.dart';
import 'package:akka_food/features/leaderboard/domain/entities/leaderboard_period.dart';

void main() {
  // ---------------------------------------------------------------------------
  // LeaderboardPaths.collection
  // ---------------------------------------------------------------------------

  group('LeaderboardPaths — collection constant', () {
    test('collection is "leaderboard"', () {
      expect(LeaderboardPaths.collection, equals('leaderboard'));
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardPaths.monthlyDocId
  // ---------------------------------------------------------------------------

  group('LeaderboardPaths.monthlyDocId', () {
    test('formats as monthly_YYYY_MM with zero-padded month', () {
      final date = DateTime(2024, 6, 15);
      expect(LeaderboardPaths.monthlyDocId(date), equals('monthly_2024_06'));
    });

    test('handles January (single-digit month)', () {
      final date = DateTime(2025, 1, 1);
      expect(LeaderboardPaths.monthlyDocId(date), equals('monthly_2025_01'));
    });

    test('handles December (double-digit month)', () {
      final date = DateTime(2024, 12, 31);
      expect(LeaderboardPaths.monthlyDocId(date), equals('monthly_2024_12'));
    });

    test('uses current date when no argument provided', () {
      final now = DateTime.now();
      final expected =
          'monthly_${now.year}_${now.month.toString().padLeft(2, '0')}';
      expect(LeaderboardPaths.monthlyDocId(), equals(expected));
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardPaths.monthlyPath
  // ---------------------------------------------------------------------------

  group('LeaderboardPaths.monthlyPath', () {
    test('returns full path with collection prefix', () {
      final date = DateTime(2024, 6, 15);
      expect(
        LeaderboardPaths.monthlyPath(date),
        equals('leaderboard/monthly_2024_06'),
      );
    });

    test('returns full path for a different month', () {
      final date = DateTime(2023, 11, 1);
      expect(
        LeaderboardPaths.monthlyPath(date),
        equals('leaderboard/monthly_2023_11'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardPaths.weeklyDocId
  // ---------------------------------------------------------------------------

  group('LeaderboardPaths.weeklyDocId', () {
    test('formats as weekly_YYYY_WW with zero-padded week', () {
      // 2024-01-08 is Monday of ISO week 2
      final date = DateTime(2024, 1, 8);
      expect(LeaderboardPaths.weeklyDocId(date), equals('weekly_2024_02'));
    });

    test('handles first week of the year', () {
      // 2024-01-04 (Thursday) is always in ISO week 1
      final date = DateTime(2024, 1, 4);
      expect(LeaderboardPaths.weeklyDocId(date), equals('weekly_2024_01'));
    });

    test('handles last week of the year', () {
      // 2024-12-30 is in ISO week 1 of 2025 (Monday Dec 30)
      // Let's use a date clearly in a late week: 2024-12-23 (Monday of week 52)
      final date = DateTime(2024, 12, 23);
      expect(LeaderboardPaths.weeklyDocId(date), equals('weekly_2024_52'));
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardPaths.weeklyPath
  // ---------------------------------------------------------------------------

  group('LeaderboardPaths.weeklyPath', () {
    test('returns full path with collection prefix', () {
      final date = DateTime(2024, 1, 8);
      expect(
        LeaderboardPaths.weeklyPath(date),
        equals('leaderboard/weekly_2024_02'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardPaths.documentId — period-based resolution
  // ---------------------------------------------------------------------------

  group('LeaderboardPaths.documentId', () {
    test('returns all_time for LeaderboardPeriod.allTime', () {
      expect(
        LeaderboardPaths.documentId(LeaderboardPeriod.allTime),
        equals('all_time'),
      );
    });

    test('returns monthly doc ID for LeaderboardPeriod.monthly', () {
      final date = DateTime(2024, 6, 15);
      expect(
        LeaderboardPaths.documentId(LeaderboardPeriod.monthly, date),
        equals('monthly_2024_06'),
      );
    });

    test('returns weekly doc ID for LeaderboardPeriod.weekly', () {
      final date = DateTime(2024, 1, 8);
      expect(
        LeaderboardPaths.documentId(LeaderboardPeriod.weekly, date),
        equals('weekly_2024_02'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardPaths.documentPath — full path resolution
  // ---------------------------------------------------------------------------

  group('LeaderboardPaths.documentPath', () {
    test('returns full path for allTime period', () {
      expect(
        LeaderboardPaths.documentPath(LeaderboardPeriod.allTime),
        equals('leaderboard/all_time'),
      );
    });

    test('returns full path for monthly period', () {
      final date = DateTime(2024, 6, 15);
      expect(
        LeaderboardPaths.documentPath(LeaderboardPeriod.monthly, date),
        equals('leaderboard/monthly_2024_06'),
      );
    });

    test('returns full path for weekly period', () {
      final date = DateTime(2024, 1, 8);
      expect(
        LeaderboardPaths.documentPath(LeaderboardPeriod.weekly, date),
        equals('leaderboard/weekly_2024_02'),
      );
    });
  });
}
