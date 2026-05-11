import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/coins/domain/entities/coin_balance.dart';
import 'package:akka_food/features/coins/domain/entities/coin_transaction.dart';
import 'package:akka_food/features/coins/domain/repositories/i_coin_repository.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser({String uid = 'uid-test'}) {
  return AppUser(
    uid: uid,
    email: 'user@example.com',
    displayName: 'Test User',
    isVerified: true,
    isDeactivated: false,
    createdAt: DateTime(2024, 1, 1),
    linkedProviders: const ['password'],
  );
}

List<CoinTransaction> _makeTransactions(int count, {int startIndex = 0}) {
  return List.generate(count, (i) {
    final index = startIndex + i;
    return CoinTransaction(
      id: 'tx_$index',
      uid: 'uid-test',
      amount: (index + 1) * 100,
      reason: index.isEven ? 'Purchase reward' : 'Redemption',
      orderId: 'order_$index',
      timestamp: DateTime(2024, 1, 1).subtract(Duration(days: index)),
    );
  });
}

// =============================================================================
// FakeCoinRepository
// =============================================================================

/// Configurable fake [ICoinRepository] for testing coin notifiers in isolation.
class FakeCoinRepository implements ICoinRepository {
  // --- Stream control ---
  StreamController<int>? _balanceController;

  /// The initial balance value emitted by [watchBalance].
  int initialBalance = 500;

  /// Transactions returned by [getTransactionHistory], keyed by page number.
  Map<int, List<CoinTransaction>> transactionPages = {};

  /// When true, [getTransactionHistory] throws an exception.
  bool throwOnGetHistory = false;

  /// Exception message when [throwOnGetHistory] is true.
  String historyErrorMessage = 'Failed to fetch history';

  // --- Call tracking ---
  final List<({String uid, int page, int pageSize})> getHistoryCalls = [];

  @override
  Stream<int> watchBalance(String uid) {
    _balanceController = StreamController<int>();
    _balanceController!.add(initialBalance);
    return _balanceController!.stream;
  }

  /// Emits a new balance value on the stream.
  void emitBalance(int balance) {
    _balanceController?.add(balance);
  }

  @override
  Future<List<CoinTransaction>> getTransactionHistory({
    required String uid,
    int page = 0,
    int pageSize = 20,
  }) async {
    getHistoryCalls.add((uid: uid, page: page, pageSize: pageSize));
    if (throwOnGetHistory) {
      throw Exception(historyErrorMessage);
    }
    return transactionPages[page] ?? [];
  }

  @override
  Future<void> redeemCoins({
    required String uid,
    required int amount,
    required String orderId,
  }) async {
    // Not tested in this file.
  }

  void dispose() {
    _balanceController?.close();
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  late ProviderContainer container;
  late FakeCoinRepository fakeRepository;

  // ---------------------------------------------------------------------------
  // coinBalanceStreamProvider
  // ---------------------------------------------------------------------------

  group('coinBalanceStreamProvider', () {
    test('emits 0 when no user is signed in', () async {
      fakeRepository = FakeCoinRepository();
      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      // Listen to the stream provider
      final sub = container.listen(
        coinBalanceStreamProvider,
        (_, __) {},
        fireImmediately: true,
      );

      // Let the stream emit
      await Future<void>.delayed(Duration.zero);

      final state = container.read(coinBalanceStreamProvider);
      expect(state.valueOrNull, equals(0));

      sub.close();
    });

    test('emits balance from repository when user is signed in', () async {
      fakeRepository = FakeCoinRepository();
      fakeRepository.initialBalance = 3500;
      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => _fakeUser()),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        coinBalanceStreamProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coinBalanceStreamProvider);
      expect(state.valueOrNull, equals(3500));

      sub.close();
    });

    test('updates when balance changes', () async {
      fakeRepository = FakeCoinRepository();
      fakeRepository.initialBalance = 1000;
      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => _fakeUser()),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final emissions = <int>[];
      final sub = container.listen(
        coinBalanceStreamProvider,
        (_, next) {
          if (next.hasValue) emissions.add(next.value!);
        },
        fireImmediately: true,
      );

      await Future<void>.delayed(Duration.zero);
      expect(emissions, contains(1000));

      // Emit a new balance
      fakeRepository.emitBalance(2000);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, contains(2000));

      sub.close();
    });
  });

  // ---------------------------------------------------------------------------
  // coinBalanceProvider
  // ---------------------------------------------------------------------------

  group('coinBalanceProvider', () {
    test('returns correct CoinBalance from raw balance', () async {
      fakeRepository = FakeCoinRepository();
      fakeRepository.initialBalance = 2500;
      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => _fakeUser()),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      // Let the stream emit
      final sub = container.listen(
        coinBalanceStreamProvider,
        (_, __) {},
        fireImmediately: true,
      );
      await Future<void>.delayed(Duration.zero);

      final balance = container.read(coinBalanceProvider);

      expect(balance.total, equals(2500));
      expect(balance.nextThreshold, equals(3000));
      expect(balance.coinsToNext, equals(500));

      sub.close();
    });

    test('returns CoinBalance(total: 0, ...) when stream has no value',
        () async {
      fakeRepository = FakeCoinRepository();
      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      // Read coinBalanceProvider before the stream has emitted
      final balance = container.read(coinBalanceProvider);

      expect(balance.total, equals(0));
      expect(balance.nextThreshold, equals(1000));
      expect(balance.coinsToNext, equals(1000));
    });
  });

  // ---------------------------------------------------------------------------
  // CoinHistoryNotifier
  // ---------------------------------------------------------------------------

  group('CoinHistoryNotifier', () {
    test('build() fetches first page of transactions', () async {
      fakeRepository = FakeCoinRepository();
      final page0 = _makeTransactions(5);
      fakeRepository.transactionPages = {0: page0};

      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => _fakeUser()),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      // Keep subscription alive
      final sub = container.listen(
        coinHistoryNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      // Wait for the async build to complete
      await container.read(coinHistoryNotifierProvider.future);

      final state = container.read(coinHistoryNotifierProvider);
      expect(state.valueOrNull, equals(page0));
      expect(fakeRepository.getHistoryCalls.length, equals(1));
      expect(fakeRepository.getHistoryCalls.first.page, equals(0));

      sub.close();
    });

    test('returns empty list when no user is signed in', () async {
      fakeRepository = FakeCoinRepository();
      fakeRepository.transactionPages = {0: _makeTransactions(5)};

      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        coinHistoryNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      final result = await container.read(coinHistoryNotifierProvider.future);

      expect(result, isEmpty);
      // Repository should not be called when no user is signed in
      expect(fakeRepository.getHistoryCalls, isEmpty);

      sub.close();
    });

    test('loadNextPage() appends next page to existing list', () async {
      fakeRepository = FakeCoinRepository();
      final page0 = _makeTransactions(kCoinPageSize);
      final page1 = _makeTransactions(5, startIndex: kCoinPageSize);
      fakeRepository.transactionPages = {0: page0, 1: page1};

      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => _fakeUser()),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        coinHistoryNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      // Wait for initial build
      await container.read(coinHistoryNotifierProvider.future);

      // Load next page
      final notifier = container.read(coinHistoryNotifierProvider.notifier);
      await notifier.loadNextPage();

      final state = container.read(coinHistoryNotifierProvider);
      final allTransactions = state.valueOrNull!;

      expect(allTransactions.length, equals(kCoinPageSize + 5));
      // First page items are still there
      expect(allTransactions.sublist(0, kCoinPageSize), equals(page0));
      // Second page items are appended
      expect(allTransactions.sublist(kCoinPageSize), equals(page1));

      sub.close();
    });

    test('loadNextPage() does nothing when hasMore is false', () async {
      fakeRepository = FakeCoinRepository();
      // Return fewer items than kCoinPageSize to signal no more pages
      final page0 = _makeTransactions(5);
      fakeRepository.transactionPages = {0: page0};

      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => _fakeUser()),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        coinHistoryNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(coinHistoryNotifierProvider.future);

      final notifier = container.read(coinHistoryNotifierProvider.notifier);
      expect(notifier.hasMore, isFalse);

      // Clear call tracking
      fakeRepository.getHistoryCalls.clear();

      // Try to load next page — should do nothing
      await notifier.loadNextPage();

      // No additional calls should have been made
      expect(fakeRepository.getHistoryCalls, isEmpty);

      final state = container.read(coinHistoryNotifierProvider);
      expect(state.valueOrNull, equals(page0));

      sub.close();
    });

    test('refresh() resets to page 0 and reloads', () async {
      fakeRepository = FakeCoinRepository();
      final page0 = _makeTransactions(kCoinPageSize);
      final page1 = _makeTransactions(5, startIndex: kCoinPageSize);
      fakeRepository.transactionPages = {0: page0, 1: page1};

      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => _fakeUser()),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        coinHistoryNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      // Initial build + load next page
      await container.read(coinHistoryNotifierProvider.future);
      final notifier = container.read(coinHistoryNotifierProvider.notifier);
      await notifier.loadNextPage();

      // Verify we have both pages
      var state = container.read(coinHistoryNotifierProvider);
      expect(state.valueOrNull!.length, equals(kCoinPageSize + 5));

      // Clear call tracking
      fakeRepository.getHistoryCalls.clear();

      // Refresh — should reset to page 0
      await notifier.refresh();

      state = container.read(coinHistoryNotifierProvider);
      expect(state.valueOrNull, equals(page0));
      expect(notifier.currentPage, equals(0));
      expect(notifier.hasMore, isTrue);

      // Verify page 0 was fetched again
      expect(fakeRepository.getHistoryCalls.any((c) => c.page == 0), isTrue);

      sub.close();
    });

    test('loadNextPage() sets error state on failure while preserving previous value',
        () async {
      fakeRepository = FakeCoinRepository();
      final page0 = _makeTransactions(kCoinPageSize);
      fakeRepository.transactionPages = {0: page0};

      container = ProviderContainer(
        overrides: [
          coinRepositoryProvider.overrideWithValue(fakeRepository),
          currentUserProvider.overrideWith((ref) => _fakeUser()),
        ],
      );
      addTearDown(() {
        container.dispose();
        fakeRepository.dispose();
      });

      final sub = container.listen(
        coinHistoryNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await container.read(coinHistoryNotifierProvider.future);

      // Enable error for next call
      fakeRepository.throwOnGetHistory = true;

      final notifier = container.read(coinHistoryNotifierProvider.notifier);
      await notifier.loadNextPage();

      final state = container.read(coinHistoryNotifierProvider);

      // Should have error
      expect(state.hasError, isTrue);
      // Previous value should be preserved
      expect(state.valueOrNull, equals(page0));

      sub.close();
    });
  });
}
