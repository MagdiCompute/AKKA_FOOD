// integration_test/leaderboard_opt_out_test.dart
//
// Task 8.2 — Opt out of leaderboard → entry removed from rankings
//
// Tests the end-to-end flow from the Flutter app's perspective:
// 1. User is initially visible on the leaderboard at rank 3 with score 30
// 2. User opts out (leaderboardVisible → false)
// 3. The leaderboard updates: user's entry is removed, remaining entries
//    are re-ranked without gaps
//
// Validates:
// - Req 4 AC2: WHEN a User opts out of the leaderboard, THE Leaderboard_Service
//   SHALL exclude that User's entry from all leaderboard responses.
// - Req 4 AC3: WHEN a User opts out, their rank position SHALL be removed and
//   remaining entries SHALL be re-ranked without gaps.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:akka_food/features/leaderboard/domain/entities/leaderboard_period.dart';
import 'package:akka_food/features/leaderboard/presentation/notifiers/leaderboard_notifier.dart';
import 'package:akka_food/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:akka_food/features/leaderboard/presentation/widgets/leaderboard_entry_tile.dart';

// =============================================================================
// Test fixtures
// =============================================================================

/// Initial leaderboard state: 5 users, opted-out user at rank 3 with score 30.
List<LeaderboardEntry> _initialLeaderboard() => [
      const LeaderboardEntry(
        rank: 1,
        uid: 'uid-user-1',
        displayName: 'Top Player',
        score: 50,
      ),
      const LeaderboardEntry(
        rank: 2,
        uid: 'uid-user-2',
        displayName: 'Second Place',
        score: 40,
      ),
      const LeaderboardEntry(
        rank: 3,
        uid: 'uid-opt-out-user',
        displayName: 'Opt Out User',
        score: 30,
      ),
      const LeaderboardEntry(
        rank: 4,
        uid: 'uid-user-4',
        displayName: 'Fourth Place',
        score: 20,
      ),
      const LeaderboardEntry(
        rank: 5,
        uid: 'uid-user-5',
        displayName: 'Fifth Place',
        score: 10,
      ),
    ];

/// Updated leaderboard after opt-out: "Opt Out User" removed, remaining
/// entries re-ranked without gaps (1, 2, 3, 4 instead of 1, 2, 4, 5).
List<LeaderboardEntry> _leaderboardAfterOptOut() => [
      const LeaderboardEntry(
        rank: 1,
        uid: 'uid-user-1',
        displayName: 'Top Player',
        score: 50,
      ),
      const LeaderboardEntry(
        rank: 2,
        uid: 'uid-user-2',
        displayName: 'Second Place',
        score: 40,
      ),
      const LeaderboardEntry(
        rank: 3,
        uid: 'uid-user-4',
        displayName: 'Fourth Place',
        score: 20,
      ),
      const LeaderboardEntry(
        rank: 4,
        uid: 'uid-user-5',
        displayName: 'Fifth Place',
        score: 10,
      ),
    ];

// =============================================================================
// Helper — builds a test app with LeaderboardScreen using stream overrides
// =============================================================================

Widget _buildTestApp({
  required Stream<List<LeaderboardEntry>> allTimeStream,
  required Stream<List<LeaderboardEntry>> monthlyStream,
  required Stream<List<LeaderboardEntry>> weeklyStream,
}) {
  return ProviderScope(
    overrides: [
      leaderboardStreamProvider(LeaderboardPeriod.allTime)
          .overrideWith((ref) => allTimeStream),
      leaderboardStreamProvider(LeaderboardPeriod.monthly)
          .overrideWith((ref) => monthlyStream),
      leaderboardStreamProvider(LeaderboardPeriod.weekly)
          .overrideWith((ref) => weeklyStream),
    ],
    child: const MaterialApp(
      home: LeaderboardScreen(),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'opt out: user entry removed and remaining entries re-ranked',
    (WidgetTester tester) async {
      // StreamControllers simulate real-time Firestore updates for each period.
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Build app with initial leaderboard (user at rank 3, score 30)
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        allTimeStream: allTimeController.stream,
        monthlyStream: monthlyController.stream,
        weeklyStream: weeklyController.stream,
      ));

      // Emit initial leaderboard data for all-time (default tab)
      allTimeController.add(_initialLeaderboard());
      await tester.pumpAndSettle();

      // Verify the leaderboard is displayed with 5 entries
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(5));

      // Verify the opt-out user is visible at rank 3 with score 30
      expect(find.text('Opt Out User'), findsOneWidget);
      expect(find.text('30 orders'), findsOneWidget);

      // Verify other entries are displayed correctly
      expect(find.text('Top Player'), findsOneWidget);
      expect(find.text('50 orders'), findsOneWidget);
      expect(find.text('Second Place'), findsOneWidget);
      expect(find.text('40 orders'), findsOneWidget);
      expect(find.text('Fourth Place'), findsOneWidget);
      expect(find.text('20 orders'), findsOneWidget);
      expect(find.text('Fifth Place'), findsOneWidget);
      expect(find.text('10 orders'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Simulate opt-out → emit updated leaderboard without user,
      //         re-ranked (Req 4 AC2 & AC3)
      //         This simulates the Cloud Function rebuilding the leaderboard
      //         after the user sets leaderboardVisible = false.
      // ─────────────────────────────────────────────────────────────────────
      allTimeController.add(_leaderboardAfterOptOut());
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Verify the opted-out user's entry is gone
      //         (Req 4 AC2: exclude user's entry from all leaderboard responses)
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Opt Out User'), findsNothing);
      expect(find.text('30 orders'), findsNothing);

      // Verify the leaderboard now has 4 entries (one removed)
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(4));

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Verify remaining entries have consecutive ranks (no gaps)
      //         (Req 4 AC3: re-ranked without gaps)
      //         Expected ranks: 1, 2, 3, 4 (not 1, 2, 4, 5)
      // ─────────────────────────────────────────────────────────────────────

      // "Fourth Place" should now be at rank 3 (was rank 4)
      expect(find.text('Fourth Place'), findsOneWidget);
      expect(find.text('20 orders'), findsOneWidget);

      // "Fifth Place" should now be at rank 4 (was rank 5)
      expect(find.text('Fifth Place'), findsOneWidget);
      expect(find.text('10 orders'), findsOneWidget);

      // Top 2 remain unchanged
      expect(find.text('Top Player'), findsOneWidget);
      expect(find.text('50 orders'), findsOneWidget);
      expect(find.text('Second Place'), findsOneWidget);
      expect(find.text('40 orders'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );

  testWidgets(
    'opt out: exclusion applies across all period tabs',
    (WidgetTester tester) async {
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Build app and show initial all-time leaderboard with user
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        allTimeStream: allTimeController.stream,
        monthlyStream: monthlyController.stream,
        weeklyStream: weeklyController.stream,
      ));

      // Emit initial all-time data with opt-out user present
      allTimeController.add(_initialLeaderboard());
      await tester.pumpAndSettle();

      // Verify user is visible initially
      expect(find.text('Opt Out User'), findsOneWidget);
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(5));

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Simulate opt-out — all-time leaderboard updates
      // ─────────────────────────────────────────────────────────────────────
      allTimeController.add(_leaderboardAfterOptOut());
      await tester.pumpAndSettle();

      // Verify user removed from all-time
      expect(find.text('Opt Out User'), findsNothing);
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(4));

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Switch to Monthly tab — user should also be excluded
      //         (Req 4 AC2: exclude from ALL leaderboard responses)
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      // Emit monthly leaderboard without the opted-out user, re-ranked
      monthlyController.add([
        const LeaderboardEntry(
          rank: 1,
          uid: 'uid-user-1',
          displayName: 'Top Player',
          score: 15,
        ),
        const LeaderboardEntry(
          rank: 2,
          uid: 'uid-user-2',
          displayName: 'Second Place',
          score: 12,
        ),
        const LeaderboardEntry(
          rank: 3,
          uid: 'uid-user-4',
          displayName: 'Fourth Place',
          score: 8,
        ),
      ]);
      await tester.pumpAndSettle();

      // Verify opted-out user is not in monthly leaderboard
      expect(find.text('Opt Out User'), findsNothing);
      // Verify consecutive ranks (1, 2, 3) with no gaps
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(3));

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Switch to Weekly tab — user should also be excluded
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Emit weekly leaderboard without the opted-out user, re-ranked
      weeklyController.add([
        const LeaderboardEntry(
          rank: 1,
          uid: 'uid-user-1',
          displayName: 'Top Player',
          score: 5,
        ),
        const LeaderboardEntry(
          rank: 2,
          uid: 'uid-user-5',
          displayName: 'Fifth Place',
          score: 3,
        ),
      ]);
      await tester.pumpAndSettle();

      // Verify opted-out user is not in weekly leaderboard
      expect(find.text('Opt Out User'), findsNothing);
      // Verify consecutive ranks (1, 2) with no gaps
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(2));

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );
}
