import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/user_profile/domain/entities/order_summary.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_order_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/order_history_notifier.dart';

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

OrderSummary _fakeOrder({
  String orderId = 'order-1',
  String status = 'delivered',
  double totalAmount = 5000,
}) {
  return OrderSummary(
    orderId: orderId,
    orderDate: DateTime(2024, 6, 1),
    items: const [
      OrderItem(name: 'Jollof Rice', quantity: 2, unitPrice: 2500),
    ],
    totalAmount: totalAmount,
    status: status,
    paymentMethod: 'mobile_money',
  );
}

List<OrderSummary> _generateOrders(int count) {
  return List.generate(
    count,
    (i) => _fakeOrder(orderId: 'order-${i + 1}', totalAmount: (i + 1) * 1000),
  );
}

// =============================================================================
// FakeOrderRepository
// =============================================================================

class FakeOrderRepository implements IOrderRepository {
  List<OrderSummary> firstPageOrders;
  List<OrderSummary> secondPageOrders;

  bool throwOnGetOrderHistory = false;
  bool throwOnGetOrderDetail = false;

  FakeOrderRepository({
    List<OrderSummary>? firstPage,
    List<OrderSummary>? secondPage,
  })  : firstPageOrders = firstPage ?? [],
        secondPageOrders = secondPage ?? [];

  @override
  Future<List<OrderSummary>> getOrderHistory(
    String uid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (throwOnGetOrderHistory) throw Exception('getOrderHistory failed');
    return page == 1 ? firstPageOrders : secondPageOrders;
  }

  @override
  Future<OrderSummary> getOrderDetail(String orderId) async {
    if (throwOnGetOrderDetail) throw Exception('getOrderDetail failed');
    return firstPageOrders.firstWhere((o) => o.orderId == orderId);
  }

  @override
  Stream<List<OrderSummary>> watchOrderHistory(
    String uid, {
    int pageSize = 20,
  }) {
    if (throwOnGetOrderHistory) throw Exception('watchOrderHistory failed');
    return Stream.value(firstPageOrders);
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('OrderHistoryNotifier', () {
    // -------------------------------------------------------------------------
    // build()
    // -------------------------------------------------------------------------

    group('build()', () {
      test('returns order list from repository when user is signed in',
          () async {
        final orders = _generateOrders(3);
        final repo = FakeOrderRepository(firstPage: orders);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(orderHistoryNotifierProvider.future);

        expect(result, hasLength(3));
        expect(result.first.orderId, equals('order-1'));
      });

      test('returns empty list when no user is signed in', () async {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            orderRepositoryProvider.overrideWith(
              (_) async => FakeOrderRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(orderHistoryNotifierProvider.future);

        expect(result, isEmpty);
      });

      test('hasMore is false when first page has fewer than 20 items — '
          'loadNextPage does not fetch more', () async {
        final orders = _generateOrders(5); // less than default page size of 20
        final repo = FakeOrderRepository(firstPage: orders);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(orderHistoryNotifierProvider.future);

        // Calling loadNextPage when hasMore should be false must not append items
        await container
            .read(orderHistoryNotifierProvider.notifier)
            .loadNextPage();

        final state = container.read(orderHistoryNotifierProvider);
        // List stays at 5 — no second page was fetched
        expect(state.value!, hasLength(5));
      });

      test('hasMore is true when first page has exactly 20 items — '
          'loadNextPage fetches more', () async {
        final orders = _generateOrders(20);
        final page2 = [_fakeOrder(orderId: 'order-21')];
        final repo = FakeOrderRepository(firstPage: orders, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(orderHistoryNotifierProvider.future);

        await container
            .read(orderHistoryNotifierProvider.notifier)
            .loadNextPage();

        final state = container.read(orderHistoryNotifierProvider);
        // Page 2 was fetched and appended
        expect(state.value!, hasLength(21));
      });
    });

    // -------------------------------------------------------------------------
    // loadNextPage()
    // -------------------------------------------------------------------------

    group('loadNextPage()', () {
      test('appends next page orders to existing list on success', () async {
        final page1 = _generateOrders(20);
        final page2 = [_fakeOrder(orderId: 'order-21')];
        final repo = FakeOrderRepository(firstPage: page1, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(orderHistoryNotifierProvider.future);

        await container
            .read(orderHistoryNotifierProvider.notifier)
            .loadNextPage();

        final state = container.read(orderHistoryNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!, hasLength(21));
        expect(state.value!.last.orderId, equals('order-21'));
      });

      test('advances currentPage counter on success', () async {
        final page1 = _generateOrders(20);
        final page2 = _generateOrders(5);
        final repo = FakeOrderRepository(firstPage: page1, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(orderHistoryNotifierProvider.future);

        final notifier = container.read(orderHistoryNotifierProvider.notifier);
        expect(notifier.currentPage, equals(1));

        await notifier.loadNextPage();

        expect(notifier.currentPage, equals(2));
      });

      test('sets hasMore to false when next page has fewer than 20 items',
          () async {
        final page1 = _generateOrders(20);
        final page2 = _generateOrders(3); // partial page
        final repo = FakeOrderRepository(firstPage: page1, secondPage: page2);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(orderHistoryNotifierProvider.future);

        final notifier = container.read(orderHistoryNotifierProvider.notifier);
        await notifier.loadNextPage();

        expect(notifier.hasMore, isFalse);
      });

      test('does nothing when first page has fewer than 20 items', () async {
        final orders = _generateOrders(3); // less than 20 → hasMore = false
        final repo = FakeOrderRepository(firstPage: orders);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(orderHistoryNotifierProvider.future);

        final notifier = container.read(orderHistoryNotifierProvider.notifier);

        await notifier.loadNextPage();

        final state = container.read(orderHistoryNotifierProvider);
        // List stays at 3 — no additional items were appended
        expect(state.value!, hasLength(3));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final page1 = _generateOrders(20);
        final repo = FakeOrderRepository(firstPage: page1)
          ..throwOnGetOrderHistory = true;
        // We need the first build to succeed, then fail on loadNextPage.
        // Use a repo that only fails on page > 1.
        final smartRepo = _SmartFailRepo(firstPage: page1);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => smartRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(orderHistoryNotifierProvider.future);

        await container
            .read(orderHistoryNotifierProvider.notifier)
            .loadNextPage();

        final state = container.read(orderHistoryNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!, hasLength(20));
      });
    });

    // -------------------------------------------------------------------------
    // refresh()
    // -------------------------------------------------------------------------

    group('refresh()', () {
      test('resets to page 1 and reloads from scratch', () async {
        final orders = _generateOrders(5);
        final repo = FakeOrderRepository(firstPage: orders);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            orderRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(orderHistoryNotifierProvider.future);

        final notifier = container.read(orderHistoryNotifierProvider.notifier);
        await notifier.refresh();

        expect(notifier.currentPage, equals(1));
        final state = container.read(orderHistoryNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!, hasLength(5));
      });
    });
  });
}

// =============================================================================
// Helper: repo that fails only on page 2+
// =============================================================================

class _SmartFailRepo implements IOrderRepository {
  final List<OrderSummary> firstPage;

  _SmartFailRepo({required this.firstPage});

  @override
  Future<List<OrderSummary>> getOrderHistory(
    String uid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (page > 1) throw Exception('page 2 failed');
    return firstPage;
  }

  @override
  Future<OrderSummary> getOrderDetail(String orderId) async {
    return firstPage.firstWhere((o) => o.orderId == orderId);
  }

  @override
  Stream<List<OrderSummary>> watchOrderHistory(
    String uid, {
    int pageSize = 20,
  }) {
    return Stream.value(firstPage);
  }
}
