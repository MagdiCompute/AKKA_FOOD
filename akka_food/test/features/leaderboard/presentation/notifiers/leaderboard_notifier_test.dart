import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:akka_food/features/leaderboard/domain/entities/leaderboard_period.dart';
import 'package:akka_food/features/leaderboard/domain/repositories/i_leaderboard_repository.dart';
import 'package:akka_food/features/leaderboard/presentation/notifiers/leaderboard_notifier.dart';

// =============================================================================
// Test fixtures
// =============================================================================

List<LeaderboardEntry> _makeEntries(int count, {int startRank = 1}) {
  return List.generate(count, (i) {
    final rank = startRank + i;
    return LeaderboardEntry(
      rank: rank,
      uid: 'user_$rank',
      displayName: 'User $rank',
      avatarUrl: 'https://example.com/avatar_$rank.png',
      score: 100 - rank,
      isCurrentUser: false,
    );
  });
}

LeaderboardEntry _currentUserEntry({
  int rank = 5,
  String uid = 'current_user',
  int score = 95,
}) {
  return LeaderboardEntry(
    rank: rank,
    uid: uid,
    displayName: 'Current User',
    avatarUrl: 'https://example.com/current.png',
    score: score,
    isCurrentUser: true,
  );
}

// =============================================================================
// FakeLeaderboardRepository
// =============================================================================

/// Configurable fake [ILeaderboardRepository] for testing the leaderboard
/// notifier in isolation.
class FakeLeaderboardRepository implements ILeaderboardRepository {
  // --- Configuration ---

  /// Entries returned by [getLeaderboard], keyed by period.
  Map<LeaderboardPeriod, List<LeaderboardEntry>> leaderboardData = {};

  /// Entry returned by [getCurrentUserEntry], keyed by period.
  Map<LeaderboardPeriod, LeaderboardEntry?> userEntryData = {};

  /// Stream controllers for [watchLeaderboard], keyed by period.
  final Map<LeaderboardPeriod, StreamController<List<LeaderboardEntry>>>
      _streamControllers = {};

  /// When true, [getLeaderboard] throws an exception.
  bool throwOnGetLeaderboard = false;

  /// When true, [getCurrentUserEntry] throws an exception.
  bool throwOnGetCurrentUserEntry = false;

  /// Exception message for errors.
  String errorMessage = 'Repository error';

  // --- Call tracking ---
  final List<LeaderboardPeriod> getLeaderboardCalls = [];
  final List<LeaderboardPeriod> getCurrentUserEntryCalls = [];
  final List<LeaderboardPeriod> watchLeaderboardCalls = [];

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
      LeaderboardPeriod period) async {
    getLeaderboardCalls.add(period);
    if (throwOnGetLeaderboard) {
      throw Exception(errorMessage);
    }
    return leaderboardData[period] ?? [];
  }

  @override
  Future<LeaderboardEntry?> getCurrentUserEntry(
      LeaderboardPeriod period) async {
    getCurrentUserEntryCalls.add(period);
    if (throwOnGetCurrentUserEntry) {
      throw Exception(errorMessage);
    }
    return userEntryData[period];
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard(LeaderboardPeriod period) {
    watchLeaderboardCalls.add(period);
    _streamControllers[period] ??= StreamController<List<LeaderboardEntry>>.broadcast();
    return _streamControllers[period]!.stream;
  }

  /// Emits entries on the watch stream for the given period.
  void emitLeaderboard(LeaderboardPeriod period, List<LeaderboardEntry> entries) {
    _streamControllers[period]?.add(entries);
  }

  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  late ProviderContainer container;
  late FakeLeaderboardRepository fakeRepository;

  // ---------------------------------------------------------------------------
  // LeaderboardNotifier — Initial build
  // ---------------------------------------------------------------------------

  group('LeaderboardNotifier — Initial build', () {
    test('starts in loading state', () {
      fakeRepository = FakeLeaderboardRepository();
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: _makeEntries(10),
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      // Read immediately before async build completes
      final state = container.read(leaderboardNotifierProvider);
      expect(state.isLoading, isTrue);
    });

    test('fetches all-time leaderboard on build', () async {
      fakeRepository = FakeLeaderboardRepository();
      final entries = _makeEntries(10);
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: entries,
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      expect(fakeRepository.getLeaderboardCalls, contains(LeaderboardPeriod.allTime));

      sub.close();
    });

    test('sets data state with entries on success', () async {
      fakeRepository = FakeLeaderboardRepository();
      final entries = _makeEntries(10);
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: entries,
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      final state = container.read(leaderboardNotifierProvider);
      expect(state.hasValue, isTrue);
      expect(state.valueOrNull, equals(entries));

      sub.close();
    });

    test('sets error state on failure', () async {
      fakeRepository = FakeLeaderboardRepository();
      fakeRepository.throwOnGetLeaderboard = true;
      fakeRepository.errorMessage = 'Network error';

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      // Wait for the async build to settle
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(leaderboardNotifierProvider);
      expect(state.hasError, isTrue);

      sub.close();
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardNotifier — loadLeaderboard
  // ---------------------------------------------------------------------------

  group('LeaderboardNotifier — loadLeaderboard', () {
    test('updates state to loading (preserving previous data)', () async {
      fakeRepository = FakeLeaderboardRepository();
      final allTimeEntries = _makeEntries(5);
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: allTimeEntries,
        LeaderboardPeriod.monthly: _makeEntries(3),
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      // Wait for initial build
      await container.read(leaderboardNotifierProvider.future);

      // Track states during loadLeaderboard
      final states = <AsyncValue<List<LeaderboardEntry>>>[];
      container.listen(
        leaderboardNotifierProvider,
        (_, next) => states.add(next),
      );

      final notifier = container.read(leaderboardNotifierProvider.notifier);
      await notifier.loadLeaderboard(LeaderboardPeriod.monthly);

      // The first state emitted should be loading with previous data
      expect(states.isNotEmpty, isTrue);
      final loadingState = states.first;
      expect(loadingState.isLoading, isTrue);
      expect(loadingState.valueOrNull, equals(allTimeEntries));

      sub.close();
    });

    test('fetches entries for the specified period', () async {
      fakeRepository = FakeLeaderboardRepository();
      final weeklyEntries = _makeEntries(7);
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: _makeEntries(10),
        LeaderboardPeriod.weekly: weeklyEntries,
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      final notifier = container.read(leaderboardNotifierProvider.notifier);
      await notifier.loadLeaderboard(LeaderboardPeriod.weekly);

      final state = container.read(leaderboardNotifierProvider);
      expect(state.valueOrNull, equals(weeklyEntries));
      expect(
        fakeRepository.getLeaderboardCalls,
        contains(LeaderboardPeriod.weekly),
      );

      sub.close();
    });

    test('updates currentPeriod to the new period', () async {
      fakeRepository = FakeLeaderboardRepository();
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: _makeEntries(5),
        LeaderboardPeriod.monthly: _makeEntries(3),
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      final notifier = container.read(leaderboardNotifierProvider.notifier);
      expect(notifier.currentPeriod, equals(LeaderboardPeriod.allTime));

      await notifier.loadLeaderboard(LeaderboardPeriod.monthly);
      expect(notifier.currentPeriod, equals(LeaderboardPeriod.monthly));

      sub.close();
    });

    test('sets error state on failure (preserving previous data)', () async {
      fakeRepository = FakeLeaderboardRepository();
      final allTimeEntries = _makeEntries(5);
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: allTimeEntries,
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      // Enable error for next call
      fakeRepository.throwOnGetLeaderboard = true;

      final notifier = container.read(leaderboardNotifierProvider.notifier);
      await notifier.loadLeaderboard(LeaderboardPeriod.weekly);

      final state = container.read(leaderboardNotifierProvider);
      expect(state.hasError, isTrue);
      // Previous value should be preserved
      expect(state.valueOrNull, equals(allTimeEntries));

      sub.close();
    });
  });

  // ---------------------------------------------------------------------------
  // LeaderboardNotifier — getCurrentUserEntry
  // ---------------------------------------------------------------------------

  group('LeaderboardNotifier — getCurrentUserEntry', () {
    test('returns the user entry when found in top 100', () async {
      fakeRepository = FakeLeaderboardRepository();
      final userEntry = _currentUserEntry(rank: 5, score: 95);
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: _makeEntries(10),
      };
      fakeRepository.userEntryData = {
        LeaderboardPeriod.allTime: userEntry,
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      final notifier = container.read(leaderboardNotifierProvider.notifier);
      final result =
          await notifier.getCurrentUserEntry(LeaderboardPeriod.allTime);

      expect(result, equals(userEntry));
      expect(result!.rank, equals(5));
      expect(result.isCurrentUser, isTrue);

      sub.close();
    });

    test('returns the user entry with computed rank when outside top 100',
        () async {
      fakeRepository = FakeLeaderboardRepository();
      final userEntry = _currentUserEntry(rank: 150, score: 10);
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: _makeEntries(10),
      };
      fakeRepository.userEntryData = {
        LeaderboardPeriod.allTime: userEntry,
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      final notifier = container.read(leaderboardNotifierProvider.notifier);
      final result =
          await notifier.getCurrentUserEntry(LeaderboardPeriod.allTime);

      expect(result, equals(userEntry));
      expect(result!.rank, equals(150));

      sub.close();
    });

    test('returns null when no user is signed in', () async {
      fakeRepository = FakeLeaderboardRepository();
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: _makeEntries(10),
      };
      // Repository returns null for getCurrentUserEntry (simulating no user)
      fakeRepository.userEntryData = {
        LeaderboardPeriod.allTime: null,
      };

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      final notifier = container.read(leaderboardNotifierProvider.notifier);
      final result =
          await notifier.getCurrentUserEntry(LeaderboardPeriod.allTime);

      expect(result, isNull);

      sub.close();
    });

    test('returns null on error', () async {
      fakeRepository = FakeLeaderboardRepository();
      fakeRepository.leaderboardData = {
        LeaderboardPeriod.allTime: _makeEntries(10),
      };
      fakeRepository.throwOnGetCurrentUserEntry = true;

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(leaderboardNotifierProvider.future);

      final notifier = container.read(leaderboardNotifierProvider.notifier);
      final result =
          await notifier.getCurrentUserEntry(LeaderboardPeriod.allTime);

      expect(result, isNull);

      sub.close();
    });
  });

  // ---------------------------------------------------------------------------
  // leaderboardStreamProvider
  // ---------------------------------------------------------------------------

  group('leaderboardStreamProvider', () {
    test('emits entries from the repository watchLeaderboard stream', () async {
      fakeRepository = FakeLeaderboardRepository();
      final entries = _makeEntries(5);

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        leaderboardStreamProvider(LeaderboardPeriod.allTime),
        (_, __) {},
        fireImmediately: true,
      );

      // Emit entries on the stream
      fakeRepository.emitLeaderboard(LeaderboardPeriod.allTime, entries);
      await Future<void>.delayed(Duration.zero);

      final state =
          container.read(leaderboardStreamProvider(LeaderboardPeriod.allTime));
      expect(state.valueOrNull, equals(entries));
      expect(
        fakeRepository.watchLeaderboardCalls,
        contains(LeaderboardPeriod.allTime),
      );

      sub.close();
    });

    test('emits updated entries when the leaderboard document changes',
        () async {
      fakeRepository = FakeLeaderboardRepository();
      final initialEntries = _makeEntries(5);
      final updatedEntries = _makeEntries(7);

      container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final emissions = <List<LeaderboardEntry>>[];
      final sub = container.listen(
        leaderboardStreamProvider(LeaderboardPeriod.allTime),
        (_, next) {
          if (next.hasValue) emissions.add(next.value!);
        },
        fireImmediately: true,
      );

      // Emit initial entries
      fakeRepository.emitLeaderboard(LeaderboardPeriod.allTime, initialEntries);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, contains(initialEntries));

      // Emit updated entries (simulating leaderboard document change)
      fakeRepository.emitLeaderboard(LeaderboardPeriod.allTime, updatedEntries);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, contains(updatedEntries));
      expect(emissions.length, equals(2));

      sub.close();
    });
  });
}
