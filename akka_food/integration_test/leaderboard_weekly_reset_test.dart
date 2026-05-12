// integration_test/leaderboard_weekly_reset_test.dart
//
// Task 8.4 — Weekly reset clears weekly scores
//
// Tests that when the weekly leaderboard resets (simulated by emitting an
// empty leaderboard), the weekly scores are cleared while all-time scores
// remain unchanged.
//
// Validates:
// - Req 3 AC5: FOR the Weekly Period, THE Leaderboard_Service SHALL count
//   only orders completed within the current calendar week (Monday to Sunday).

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

/// All-Time leaderboard: cumulative scores that should NOT be affected by
/// the weekly reset.
List<LeaderboardEntry> _allTimeLeaderboard() => [
      const LeaderboardEntry(
        rank: 1,
        uid: 'uid-user-1',
        displayName: 'Power Buyer',
        score: 120,
      ),
      const LeaderboardEntry(
        rank: 2,
        uid: 'uid-user-2',
        displayName: 'Frequent Eater',
        score: 85,
      ),
      const LeaderboardEntry(
        rank: 3,
        uid: 'uid-current-user',
        displayName: 'Current User',
        score: 50,
        isCurrentUser: true,
      ),
    ];

/// Weekly leaderboard before reset: users have scores from the current week.
List<LeaderboardEntry> _weeklyBeforeReset() => [
      const LeaderboardEntry(
        rank: 1,
        uid: 'uid-user-1',
        displayName: 'Power Buyer',
        score: 5,
      ),
      const LeaderboardEntry(
        rank: 2,
        uid: 'uid-current-user',
        displayName: 'Current User',
        score: 3,
        isCurrentUser: true,
      ),
      const LeaderboardEntry(
        rank: 3,
        uid: 'uid-user-2',
        displayName: 'Frequent Eater',
        score: 2,
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
    'weekly reset: weekly scores cleared, all-time unchanged',
    (WidgetTester tester) async {
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Build app, switch to Weekly tab, show scores
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        allTimeStream: allTimeController.stream,
        monthlyStream: monthlyController.stream,
        weeklyStream: weeklyController.stream,
      ));

      // Emit all-time data for the default tab
      allTimeController.add(_allTimeLeaderboard());
      await tester.pumpAndSettle();

      // Switch to Weekly tab
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Emit weekly leaderboard with scores (before reset)
      weeklyController.add(_weeklyBeforeReset());
      await tester.pumpAndSettle();

      // Verify weekly leaderboard shows 3 entries with scores
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(3));
      expect(find.text('5 orders'), findsOneWidget); // Power Buyer
      expect(find.text('3 orders'), findsOneWidget); // Current User
      expect(find.text('2 orders'), findsOneWidget); // Frequent Eater

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Simulate weekly reset → emit empty weekly leaderboard
      //         This simulates the Cloud Function `resetWeeklyScores` running
      //         at Monday 00:00 UTC, clearing all weekly scores and the
      //         leaderboard document.
      // ─────────────────────────────────────────────────────────────────────
      weeklyController.add([]); // Empty list = reset
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Verify empty state shown for weekly
      //         (Req 3 AC5: weekly counts only current week orders)
      // ─────────────────────────────────────────────────────────────────────
      expect(find.byType(LeaderboardEntryTile), findsNothing);
      expect(find.text('No rankings this week yet'), findsOneWidget);
      expect(
        find.text(
            'A new week has started. Place an order to lead the rankings!'),
        findsOneWidget,
      );

      // Previous weekly scores should no longer be visible
      expect(find.text('5 orders'), findsNothing);
      expect(find.text('3 orders'), findsNothing);
      expect(find.text('2 orders'), findsNothing);

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Switch to All-Time → verify scores still intact
      //         All-time scores are NOT affected by the weekly reset.
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('All-Time'));
      await tester.pumpAndSettle();

      // Re-emit all-time data (stream subscription may need fresh data)
      allTimeController.add(_allTimeLeaderboard());
      await tester.pumpAndSettle();

      // Verify all-time leaderboard is still intact
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(3));
      expect(find.text('120 orders'), findsOneWidget); // Power Buyer
      expect(find.text('85 orders'), findsOneWidget); // Frequent Eater
      expect(find.text('50 orders'), findsOneWidget); // Current User

      // Verify user names are still displayed
      expect(find.text('Power Buyer'), findsOneWidget);
      expect(find.text('Frequent Eater'), findsOneWidget);
      expect(find.text('Current User'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );
}
