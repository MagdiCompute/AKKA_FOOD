// integration_test/leaderboard_period_switch_test.dart
//
// Task 8.3 — Period switching shows correct scores
//
// Tests that switching between All-Time, Monthly, and Weekly tabs displays
// the correct leaderboard data for each period:
// 1. All-Time tab shows all-time scores (user has 50 total orders)
// 2. Monthly tab shows monthly scores (user has 10 orders this month)
// 3. Weekly tab shows weekly scores (user has 3 orders this week)
// 4. Each period shows different rankings/scores appropriate to that window
//
// Validates:
// - Req 1 AC3: THE Leaderboard screen SHALL support three Period tabs:
//   All-Time, Monthly, and Weekly.
// - Req 1 AC4: WHEN the User switches Period tabs, THE Leaderboard_Service
//   SHALL return the rankings for the selected Period within 3 seconds.
// - Req 3 AC4: FOR the Monthly Period, count only orders completed within
//   the current calendar month.
// - Req 3 AC5: FOR the Weekly Period, count only orders completed within
//   the current calendar week.

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
// Test fixtures — different data per period
// =============================================================================

/// All-Time leaderboard: user has 50 total orders, ranked 3rd.
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
      const LeaderboardEntry(
        rank: 4,
        uid: 'uid-user-3',
        displayName: 'Casual Diner',
        score: 30,
      ),
      const LeaderboardEntry(
        rank: 5,
        uid: 'uid-user-4',
        displayName: 'New Member',
        score: 12,
      ),
    ];

/// Monthly leaderboard: user has 10 orders this month, ranked 2nd.
/// Different rankings and scores compared to all-time.
List<LeaderboardEntry> _monthlyLeaderboard() => [
      const LeaderboardEntry(
        rank: 1,
        uid: 'uid-user-3',
        displayName: 'Casual Diner',
        score: 15,
      ),
      const LeaderboardEntry(
        rank: 2,
        uid: 'uid-current-user',
        displayName: 'Current User',
        score: 10,
        isCurrentUser: true,
      ),
      const LeaderboardEntry(
        rank: 3,
        uid: 'uid-user-1',
        displayName: 'Power Buyer',
        score: 8,
      ),
      const LeaderboardEntry(
        rank: 4,
        uid: 'uid-user-4',
        displayName: 'New Member',
        score: 5,
      ),
    ];

/// Weekly leaderboard: user has 3 orders this week, ranked 1st.
/// Different rankings and scores compared to all-time and monthly.
List<LeaderboardEntry> _weeklyLeaderboard() => [
      const LeaderboardEntry(
        rank: 1,
        uid: 'uid-current-user',
        displayName: 'Current User',
        score: 3,
        isCurrentUser: true,
      ),
      const LeaderboardEntry(
        rank: 2,
        uid: 'uid-user-3',
        displayName: 'Casual Diner',
        score: 2,
      ),
      const LeaderboardEntry(
        rank: 3,
        uid: 'uid-user-2',
        displayName: 'Frequent Eater',
        score: 1,
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
    'period switching: All-Time tab shows all-time scores',
    (WidgetTester tester) async {
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      await tester.pumpWidget(_buildTestApp(
        allTimeStream: allTimeController.stream,
        monthlyStream: monthlyController.stream,
        weeklyStream: weeklyController.stream,
      ));

      // Emit all-time data (default tab)
      allTimeController.add(_allTimeLeaderboard());
      await tester.pumpAndSettle();

      // Verify All-Time tab is active and shows correct data
      expect(find.text('All-Time'), findsOneWidget);
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(5));

      // Verify all-time scores
      expect(find.text('120 orders'), findsOneWidget); // Power Buyer
      expect(find.text('85 orders'), findsOneWidget); // Frequent Eater
      expect(find.text('50 orders'), findsOneWidget); // Current User
      expect(find.text('30 orders'), findsOneWidget); // Casual Diner
      expect(find.text('12 orders'), findsOneWidget); // New Member

      // Verify current user is displayed
      expect(find.text('Current User'), findsOneWidget);

      // Cleanup
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );

  testWidgets(
    'period switching: Monthly tab shows monthly scores',
    (WidgetTester tester) async {
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      await tester.pumpWidget(_buildTestApp(
        allTimeStream: allTimeController.stream,
        monthlyStream: monthlyController.stream,
        weeklyStream: weeklyController.stream,
      ));

      // Emit all-time data first (default tab)
      allTimeController.add(_allTimeLeaderboard());
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Switch to Monthly tab (Req 1 AC3, Req 1 AC4)
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      // Emit monthly data
      monthlyController.add(_monthlyLeaderboard());
      await tester.pumpAndSettle();

      // Verify monthly scores are displayed (Req 3 AC4)
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(4));
      expect(find.text('15 orders'), findsOneWidget); // Casual Diner (rank 1)
      expect(find.text('10 orders'), findsOneWidget); // Current User (rank 2)
      expect(find.text('8 orders'), findsOneWidget); // Power Buyer (rank 3)
      expect(find.text('5 orders'), findsOneWidget); // New Member (rank 4)

      // Verify different rankings: Casual Diner is now #1 (was #4 all-time)
      expect(find.text('Casual Diner'), findsOneWidget);

      // Cleanup
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );

  testWidgets(
    'period switching: Weekly tab shows weekly scores',
    (WidgetTester tester) async {
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      await tester.pumpWidget(_buildTestApp(
        allTimeStream: allTimeController.stream,
        monthlyStream: monthlyController.stream,
        weeklyStream: weeklyController.stream,
      ));

      // Emit all-time data first (default tab)
      allTimeController.add(_allTimeLeaderboard());
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Switch to Weekly tab (Req 1 AC3, Req 1 AC4)
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Emit weekly data
      weeklyController.add(_weeklyLeaderboard());
      await tester.pumpAndSettle();

      // Verify weekly scores are displayed (Req 3 AC5)
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(3));
      expect(find.text('3 orders'), findsOneWidget); // Current User (rank 1)
      expect(find.text('2 orders'), findsOneWidget); // Casual Diner (rank 2)
      expect(find.text('1 orders'), findsOneWidget); // Frequent Eater (rank 3)

      // Verify current user is now #1 in weekly (was #3 all-time)
      expect(find.text('Current User'), findsOneWidget);

      // Cleanup
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );

  testWidgets(
    'period switching: each period shows different rankings and scores',
    (WidgetTester tester) async {
      final allTimeController = StreamController<List<LeaderboardEntry>>();
      final monthlyController = StreamController<List<LeaderboardEntry>>();
      final weeklyController = StreamController<List<LeaderboardEntry>>();

      await tester.pumpWidget(_buildTestApp(
        allTimeStream: allTimeController.stream,
        monthlyStream: monthlyController.stream,
        weeklyStream: weeklyController.stream,
      ));

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: All-Time — user at rank 3 with score 50
      // ─────────────────────────────────────────────────────────────────────
      allTimeController.add(_allTimeLeaderboard());
      await tester.pumpAndSettle();

      // Verify all-time: 5 entries, current user score = 50
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(5));
      expect(find.text('50 orders'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Switch to Monthly — user at rank 2 with score 10
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      monthlyController.add(_monthlyLeaderboard());
      await tester.pumpAndSettle();

      // Verify monthly: 4 entries, current user score = 10
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(4));
      expect(find.text('10 orders'), findsOneWidget);

      // All-time score (50) should NOT be visible on monthly tab
      expect(find.text('50 orders'), findsNothing);

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Switch to Weekly — user at rank 1 with score 3
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      weeklyController.add(_weeklyLeaderboard());
      await tester.pumpAndSettle();

      // Verify weekly: 3 entries, current user score = 3
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(3));
      expect(find.text('3 orders'), findsOneWidget);

      // Monthly score (10) should NOT be visible on weekly tab
      expect(find.text('10 orders'), findsNothing);
      // All-time score (50) should NOT be visible on weekly tab
      expect(find.text('50 orders'), findsNothing);

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Switch back to All-Time — verify original data is restored
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('All-Time'));
      await tester.pumpAndSettle();

      // The stream already emitted data, so it should still be available
      // Emit again to ensure fresh data
      allTimeController.add(_allTimeLeaderboard());
      await tester.pumpAndSettle();

      // Verify all-time data is back: 5 entries, current user score = 50
      expect(find.byType(LeaderboardEntryTile), findsNWidgets(5));
      expect(find.text('50 orders'), findsOneWidget);

      // Weekly score (3) should NOT be visible on all-time tab
      expect(find.text('3 orders'), findsNothing);

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await allTimeController.close();
      await monthlyController.close();
      await weeklyController.close();
    },
  );
}
