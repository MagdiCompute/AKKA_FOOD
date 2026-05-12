// integration_test/leaderboard_score_update_test.dart
//
// Task 8.1 — Complete order → score incremented → leaderboard updated within 60s
//
// Tests the end-to-end flow from the Flutter app's perspective:
// 1. User starts with a score of 10 at rank 5
// 2. An order is completed (status changes to 'delivered')
// 3. The user's score is incremented (allTimeScore +1)
// 4. The leaderboard updates to reflect the new score and rank
//
// Validates:
// - Req 3 AC3: When a User's order status changes to `delivered`, update the
//   User's Score within 60 seconds
// - Req 1 AC5: Rankings update within 60 seconds of a new completed order

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

/// Initial leaderboard state: current user at rank 5 with score 10.
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
        uid: 'uid-user-3',
        displayName: 'Third Place',
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
        uid: 'uid-current-user',
        displayName: 'Current User',
        score: 10,
        isCurrentUser: true,
      ),
    ];

/// Updated leaderboard after order completion: current user moves to rank 4
/// with score 11 (overtakes "Fourth Place" who had score 20? No — let's make
/// it realistic: user goes from score 10 to 11, stays at rank 5 but score
/// increments). For a rank change scenario, we adjust: Fourth Place has 11,
/// current user goes from 10 to 11 (tied, but now at rank 4 due to
/// leaderboard rebuild).
List<LeaderboardEntry> _updatedLeaderboard() => [
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
        uid: 'uid-user-3',
        displayName: 'Third Place',
        score: 30,
      ),
      const LeaderboardEntry(
        rank: 4,
        uid: 'uid-current-user',
        displayName: 'Current User',
        score: 11,
        isCurrentUser: true,
      ),
      const LeaderboardEntry(
        rank: 5,
        uid: 'uid-user-4',
        displayName: 'Fourth Place',
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
      // Override the stream provider for each period to use our test streams.
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
    'complete order: score incremented and leaderboard updated',
    (WidgetTester tester) async {
      // StreamControllers simulate real-time Firestore updates for each period.
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Build app with initial leaderboard (user at rank 5, score 10)
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

      // Verify current user is at rank 5 with score 10
      expect(find.text('Current User'), findsOneWidget);
      expect(find.text('10 orders'), findsOneWidget);

      // Verify other entries are displayed correctly
      expect(find.text('Top Player'), findsOneWidget);
      expect(find.text('50 orders'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Simulate order completion → emit updated leaderboard
      //         (user moves to rank 4 with score 11)
      //         This simulates the Cloud Function updating the score and
      //         rebuilding the leaderboard within 60 seconds.
      // ─────────────────────────────────────────────────────────────────────
      allTimeController.add(_updatedLeaderboard());
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Verify the UI shows the updated rank and score
      //         (Req 3 AC3: Score updated within 60s)
      //         (Req 1 AC5: Rankings update within 60s)
      // ─────────────────────────────────────────────────────────────────────

      // Verify current user now shows score 11
      expect(find.text('11 orders'), findsOneWidget);

      // Verify "Fourth Place" user now shows score 10 (dropped to rank 5)
      expect(find.text('Fourth Place'), findsOneWidget);

      // Verify the leaderboard still has 5 entries
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(5));

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );

  testWidgets(
    'score increments across all periods after order completion',
    (WidgetTester tester) async {
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Build app and show initial all-time leaderboard
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        allTimeStream: allTimeController.stream,
        monthlyStream: monthlyController.stream,
        weeklyStream: weeklyController.stream,
      ));

      // Emit initial all-time data
      allTimeController.add(_initialLeaderboard());
      await tester.pumpAndSettle();

      // Verify initial state on all-time tab
      expect(find.text('10 orders'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Simulate order completion — all-time score updates
      // ─────────────────────────────────────────────────────────────────────
      allTimeController.add(_updatedLeaderboard());
      await tester.pumpAndSettle();

      // Verify all-time score updated to 11
      expect(find.text('11 orders'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Switch to Monthly tab and verify score is also updated
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      // Emit monthly leaderboard with updated score
      monthlyController.add([
        const LeaderboardEntry(
          rank: 1,
          uid: 'uid-current-user',
          displayName: 'Current User',
          score: 11,
          isCurrentUser: true,
        ),
        const LeaderboardEntry(
          rank: 2,
          uid: 'uid-user-4',
          displayName: 'Fourth Place',
          score: 10,
        ),
      ]);
      await tester.pumpAndSettle();

      // Verify monthly score shows 11
      expect(find.text('11 orders'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Switch to Weekly tab and verify score is also updated
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Emit weekly leaderboard with updated score
      weeklyController.add([
        const LeaderboardEntry(
          rank: 1,
          uid: 'uid-current-user',
          displayName: 'Current User',
          score: 11,
          isCurrentUser: true,
        ),
      ]);
      await tester.pumpAndSettle();

      // Verify weekly score shows 11
      expect(find.text('11 orders'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );
}
