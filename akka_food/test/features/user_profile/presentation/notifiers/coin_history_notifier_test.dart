import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/user_profile/domain/entities/coin_transaction.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_coin_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/coin_history_notifier.dart';

// =============================================================================
// Test fixtures
// =============================================================================

final _fakeUser = AppUser(
  uid: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
  isVerified: true,
  isDeactivated: false,
  createdAt: DateTime(2024, 1, 1),
  linkedProviders: const ['password'],
);

CoinTransaction _fakeTx({
  String id = 'tx-1',
  int amount = 500,
  String reason = 'purchase_reward',
}) {
  return CoinTransaction(
    id: id,
    uid: 'test-uid',
    amount: amount,
    reason: reason,
    timestamp: DateTime(2024, 6, 1),
  );
}

List<CoinTransaction> _generateTxs(int count) {
  return List.generate(
    count,
    (i) => _fakeTx(id: 'tx-${i + 1}', amount: (i + 1) * 100),
  );
}

// =============================================================================
// FakeCoinRepository
// =============================================================================

class FakeCoinRepository implements ICoinRepository {
  List<CoinTransaction> firstPageTxs;
  List<CoinTransaction> secondPageTxs;
  int balance;

  bool throwOnGetCoinTransactions = false;

  FakeCoinRepository({
    List<CoinTransaction>? firstPage,
    List<CoinTransaction>? secondPage,
    this.balance = 1500,
  })  : firstPageTxs = firstPage ?? [],
        secondPageTxs = secondPage ?? [];

  @override
  Future<int> getCoinBalance(String uid) async => balance;

  @override
  Future<List<CoinTransaction>> getCoinTransactions(
    String uid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (throwOnGetCoinTransactions) throw Exception('getCoinTransactions failed');
    return page == 1 ? firstPageTxs : secondPageTxs;
  }

  @override
  Stream<int> watchCoinBalance(String uid) {
    return Stream.value(balance);
  }

  @override
  Stream<List<CoinTransaction>> watchCoinTransactions(
    String uid, {
    int pageSize = 20,
  }) {
    if (throwOnGetCoinTransactions) throw Exception('watchCoinTransactions failed');
    return Stream.value(firstPageTxs);
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('CoinHistoryNotifier', () {
    // -------------------------------------------------------------------------
    // build()
    // -------------------------------------------------------------------------

    group('build()', () {
      test('returns transaction list from repository when user is signed in',
          () async {
        final txs = _generateTxs(3);
        final repo = FakeCoinRepository(firstPage: txs);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(coinHistoryNotifierProvider.future);

        expect(result, hasLength(3));
        expect(result.first.id, equals('tx-1'));
      });

      test('returns empty list when no user is signed in', () async {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            coinRepositoryProvider.overrideWith(
              (_) async => FakeCoinRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(coinHistoryNotifierProvider.future);

        expect(result, isEmpty);
      });

      // Tests for hasMore are done indirectly via loadNextPage() behavior,
      // because _hasMore is set after the SWR stream loop completes — which
      // happens after provider.future resolves (state=AsyncData is set inside
      // the loop). Testing via loadNextPage() avoids the timing issue.
      test('when first page < 20 items, loadNextPage does not fetch more',
          () async {
        final txs = _generateTxs(5); // less than default page size of 20
        final repo = FakeCoinRepository(firstPage: txs);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(coinHistoryNotifierProvider.future);

        // loadNextPage should be a no-op when hasMore is false
        await container
            .read(coinHistoryNotifierProvider.notifier)
            .loadNextPage();

        final state = container.read(coinHistoryNotifierProvider);
        // List stays at 5 — no second page was fetched
        expect(state.value!, hasLength(5));
      });

      test('when first page == 20 items, loadNextPage fetches more', () async {
        final txs = _generateTxs(20);
        final page2 = [_fakeTx(id: 'tx-21', amount: 2100)];
        final repo = FakeCoinRepository(firstPage: txs, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(coinHistoryNotifierProvider.future);

        await container
            .read(coinHistoryNotifierProvider.notifier)
            .loadNextPage();

        final state = container.read(coinHistoryNotifierProvider);
        // Page 2 was fetched and appended
        expect(state.value!, hasLength(21));
      });
    });

    // -------------------------------------------------------------------------
    // loadNextPage()
    // -------------------------------------------------------------------------

    group('loadNextPage()', () {
      test('appends next page transactions to existing list on success',
          () async {
        final page1 = _generateTxs(20);
        final page2 = [_fakeTx(id: 'tx-21', amount: 2100)];
        final repo = FakeCoinRepository(firstPage: page1, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(coinHistoryNotifierProvider.future);

        await container
            .read(coinHistoryNotifierProvider.notifier)
            .loadNextPage();

        final state = container.read(coinHistoryNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!, hasLength(21));
        expect(state.value!.last.id, equals('tx-21'));
      });

      test('advances currentPage counter on success', () async {
        final page1 = _generateTxs(20);
        final page2 = _generateTxs(5);
        final repo = FakeCoinRepository(firstPage: page1, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(coinHistoryNotifierProvider.future);

        final notifier = container.read(coinHistoryNotifierProvider.notifier);
        expect(notifier.currentPage, equals(1));

        await notifier.loadNextPage();

        expect(notifier.currentPage, equals(2));
      });

      test('sets hasMore to false when next page has fewer than 20 items',
          () async {
        final page1 = _generateTxs(20);
        final page2 = _generateTxs(2);
        final repo = FakeCoinRepository(firstPage: page1, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(coinHistoryNotifierProvider.future);

        final notifier = container.read(coinHistoryNotifierProvider.notifier);
        await notifier.loadNextPage();

        expect(notifier.hasMore, isFalse);
      });

      test('does not fetch a third page when second page was partial', () async {
        final page1 = _generateTxs(20);
        final page2 = _generateTxs(3); // partial → hasMore = false after page 2
        final repo = FakeCoinRepository(firstPage: page1, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(coinHistoryNotifierProvider.future);

        final notifier = container.read(coinHistoryNotifierProvider.notifier);
        await notifier.loadNextPage(); // loads page 2 (3 items)

        // Try to load page 3 — should be a no-op
        await notifier.loadNextPage();

        final state = container.read(coinHistoryNotifierProvider);
        expect(state.value!, hasLength(23)); // 20 + 3, no more
        expect(notifier.currentPage, equals(2));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final page1 = _generateTxs(20);
        final smartRepo = _SmartFailCoinRepo(firstPage: page1);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => smartRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(coinHistoryNotifierProvider.future);

        await container
            .read(coinHistoryNotifierProvider.notifier)
            .loadNextPage();

        final state = container.read(coinHistoryNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!, hasLength(20));
      });
    });

    // -------------------------------------------------------------------------
    // refresh()
    // -------------------------------------------------------------------------

    group('refresh()', () {
      test('resets to page 1 and reloads from scratch', () async {
        final txs = _generateTxs(5);
        final repo = FakeCoinRepository(firstPage: txs);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            coinRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(coinHistoryNotifierProvider.future);

        final notifier = container.read(coinHistoryNotifierProvider.notifier);
        await notifier.refresh();

        expect(notifier.currentPage, equals(1));
        final state = container.read(coinHistoryNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!, hasLength(5));
      });
    });
  });

  // ---------------------------------------------------------------------------
  // coinBalanceProvider
  // ---------------------------------------------------------------------------

  group('coinBalanceProvider', () {
    test('emits balance from repository when user is signed in', () async {
      final repo = FakeCoinRepository(balance: 3500);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _fakeUser),
          coinRepositoryProvider.overrideWith((_) async => repo),
        ],
      );
      addTearDown(container.dispose);

      final balance = await container.read(coinBalanceProvider.future);

      expect(balance, equals(3500));
    });

    test('emits 0 when no user is signed in', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          coinRepositoryProvider.overrideWith(
            (_) async => FakeCoinRepository(balance: 9999),
          ),
        ],
      );
      addTearDown(container.dispose);

      final balance = await container.read(coinBalanceProvider.future);

      expect(balance, equals(0));
    });
  });
}

// =============================================================================
// Helper: repo that fails only on page 2+
// =============================================================================

class _SmartFailCoinRepo implements ICoinRepository {
  final List<CoinTransaction> firstPage;

  _SmartFailCoinRepo({required this.firstPage});

  @override
  Future<int> getCoinBalance(String uid) async => 0;

  @override
  Future<List<CoinTransaction>> getCoinTransactions(
    String uid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (page > 1) throw Exception('page 2 failed');
    return firstPage;
  }

  @override
  Stream<int> watchCoinBalance(String uid) {
    return Stream.value(0);
  }

  @override
  Stream<List<CoinTransaction>> watchCoinTransactions(
    String uid, {
    int pageSize = 20,
  }) {
    return Stream.value(firstPage);
  }
}
