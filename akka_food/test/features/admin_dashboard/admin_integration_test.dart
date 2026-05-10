// Integration tests for the Admin Dashboard feature.
//
// These tests verify end-to-end flows using fake repository implementations
// and Riverpod provider overrides — no Firebase emulator required.
//
// Covered scenarios:
//   9.2 Admin creates meal → appears in catalog (meal list notifier)
//   9.3 Admin updates order status → state reflects new status
//   9.4 Admin deactivates user → user marked as deactivated in state
//   9.5 Analytics data refreshes (real-time listener delivers updates)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/admin_dashboard/domain/entities/admin_order_view.dart';
import 'package:akka_food/features/admin_dashboard/domain/entities/admin_user_view.dart';
import 'package:akka_food/features/admin_dashboard/domain/entities/meal.dart';
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_analytics_repository.dart';
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_meal_repository.dart';
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_order_repository.dart';
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_user_repository.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_analytics_notifier.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_meal_notifier.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_order_notifier.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_user_notifier.dart';

// ---------------------------------------------------------------------------
// ReplaySubject — a minimal broadcast stream that replays the latest value
// to new subscribers (no rxdart dependency needed).
// ---------------------------------------------------------------------------

class _ReplaySubject<T> {
  _ReplaySubject([T? seed]) : _hasSeed = seed != null, _seed = seed;

  final _controller = StreamController<T>.broadcast();
  T? _seed;
  bool _hasSeed;

  Stream<T> get stream {
    final self = this;
    return Stream<T>.multi((controller) {
      if (self._hasSeed) controller.add(self._seed as T);
      final sub = self._controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  void add(T value) {
    _seed = value;
    _hasSeed = true;
    _controller.add(value);
  }

  void addError(Object error) => _controller.addError(error);

  Future<void> close() => _controller.close();
}

// ---------------------------------------------------------------------------
// Helper: pump until a provider has data (or timeout)
// ---------------------------------------------------------------------------

/// Subscribes to [provider] and waits until it emits [AsyncData], then
/// returns the value.
///
/// Uses [ProviderContainer.listen] to keep the auto-dispose provider alive
/// while we wait for the stream to deliver its first event.
Future<T> _awaitData<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider, {
  int maxAttempts = 50,
}) async {
  // Attach a listener so the auto-dispose provider stays alive.
  final sub = container.listen<AsyncValue<T>>(provider, (_, __) {});
  try {
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final value = container.read(provider);
      if (value is AsyncData<T>) return value.value;
    }
    final last = container.read(provider);
    if (last is AsyncData<T>) return last.value;
    throw StateError(
        'Provider did not emit data after $maxAttempts attempts. Last: $last');
  } finally {
    sub.close();
  }
}

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class FakeAdminMealRepository implements IAdminMealRepository {
  FakeAdminMealRepository({List<Meal>? initial}) {
    if (initial != null) _meals = List.of(initial);
    _subject = _ReplaySubject<List<Meal>>(List.of(_meals));
  }

  late final _ReplaySubject<List<Meal>> _subject;
  List<Meal> _meals = [];

  @override
  Stream<List<Meal>> watchAllMeals() => _subject.stream;

  @override
  Future<List<Meal>> getAllMeals() async => List.of(_meals);

  @override
  Future<void> toggleAvailability(String mealId,
      {required bool isAvailable}) async {
    _meals = _meals
        .map((m) => m.id == mealId ? m.copyWith(isAvailable: isAvailable) : m)
        .toList();
    _subject.add(List.of(_meals));
  }

  @override
  Future<String> createMeal(Map<String, dynamic> data) async {
    final id = 'meal_${_meals.length + 1}';
    _meals = [
      ..._meals,
      Meal(
        id: id,
        name: data['name'] as String? ?? 'New Meal',
        description: data['description'] as String? ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        category: data['category'] as String? ?? '',
        imageUrls: const [],
        isAvailable: data['isAvailable'] as bool? ?? true,
        isFeatured: data['isFeatured'] as bool? ?? false,
        createdAt: DateTime.now(),
      ),
    ];
    _subject.add(List.of(_meals));
    return id;
  }

  @override
  Future<void> updateMeal(String mealId, Map<String, dynamic> data) async {}

  @override
  Future<void> deleteMeal(String mealId) async {
    _meals = _meals.where((m) => m.id != mealId).toList();
    _subject.add(List.of(_meals));
  }

  Future<void> dispose() => _subject.close();
}

class FakeAdminOrderRepository implements IAdminOrderRepository {
  FakeAdminOrderRepository({List<AdminOrderView>? initial}) {
    if (initial != null) _orders = List.of(initial);
    _subject = _ReplaySubject<List<AdminOrderView>>(List.of(_orders));
  }

  late final _ReplaySubject<List<AdminOrderView>> _subject;
  List<AdminOrderView> _orders = [];

  @override
  Stream<List<AdminOrderView>> watchActiveOrders() => _subject.stream;

  @override
  Future<AdminOrderView?> getOrderById(String orderId) async =>
      _orders.where((o) => o.orderId == orderId).firstOrNull;

  @override
  Future<void> updateOrderStatus(String orderId, DeliveryStatus status,
      {int? etaMinutes}) async {
    _orders = _orders
        .map((o) => o.orderId == orderId
            ? o.copyWith(status: status, etaMinutes: etaMinutes)
            : o)
        .toList();
    _subject.add(List.of(_orders));
  }

  Future<void> dispose() => _subject.close();
}

class FakeAdminUserRepository implements IAdminUserRepository {
  FakeAdminUserRepository({List<AdminUserView>? initial}) {
    if (initial != null) _users = List.of(initial);
    _subject = _ReplaySubject<List<AdminUserView>>(List.of(_users));
  }

  late final _ReplaySubject<List<AdminUserView>> _subject;
  List<AdminUserView> _users = [];

  @override
  Stream<List<AdminUserView>> watchAllUsers() => _subject.stream;

  @override
  Future<AdminUserView?> getUserById(String uid) async =>
      _users.where((u) => u.uid == uid).firstOrNull;

  @override
  Future<List<AdminOrderView>> getUserOrders(String uid) async => [];

  @override
  Future<void> deactivateUser(String uid) async {
    _users = _users
        .map((u) => u.uid == uid ? u.copyWith(isDeactivated: true) : u)
        .toList();
    _subject.add(List.of(_users));
  }

  @override
  Future<void> reactivateUser(String uid) async {
    _users = _users
        .map((u) => u.uid == uid ? u.copyWith(isDeactivated: false) : u)
        .toList();
    _subject.add(List.of(_users));
  }

  Future<void> dispose() => _subject.close();
}

class _ThrowingUserRepository implements IAdminUserRepository {
  _ThrowingUserRepository({required List<AdminUserView> initial}) {
    _subject = _ReplaySubject<List<AdminUserView>>(List.of(initial));
    _users = List.of(initial);
  }

  late final _ReplaySubject<List<AdminUserView>> _subject;
  List<AdminUserView> _users = [];

  @override
  Stream<List<AdminUserView>> watchAllUsers() => _subject.stream;

  @override
  Future<AdminUserView?> getUserById(String uid) async =>
      _users.where((u) => u.uid == uid).firstOrNull;

  @override
  Future<List<AdminOrderView>> getUserOrders(String uid) async => [];

  @override
  Future<void> deactivateUser(String uid) async =>
      throw Exception('Simulated deactivation failure');

  @override
  Future<void> reactivateUser(String uid) async {}
}

class _FakeAnalyticsRepository implements IAdminAnalyticsRepository {
  _FakeAnalyticsRepository() {
    _subject = _ReplaySubject<Map<String, dynamic>>();
  }

  late final _ReplaySubject<Map<String, dynamic>> _subject;

  void add(Map<String, dynamic> doc) => _subject.add(doc);
  void addError(Object error) => _subject.addError(error);

  @override
  Stream<Map<String, dynamic>> watchSummary() => _subject.stream;
}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

Meal _makeMeal({
  String id = 'meal_1',
  String name = 'Jollof Rice',
  bool isAvailable = true,
}) =>
    Meal(
      id: id,
      name: name,
      description: 'Delicious jollof rice',
      price: 3500,
      category: 'Rice',
      imageUrls: const [],
      isAvailable: isAvailable,
      isFeatured: false,
      createdAt: DateTime(2024, 1, 1),
    );

AdminOrderView _makeOrder({
  String orderId = 'order_1',
  DeliveryStatus status = DeliveryStatus.pending,
}) =>
    AdminOrderView(
      orderId: orderId,
      uid: 'user_1',
      userDisplayName: 'Alice',
      items: const [],
      total: 5000,
      deliveryOption: DeliveryOption.delivery,
      status: status,
      createdAt: DateTime(2024, 6, 1),
    );

AdminUserView _makeUserView({
  String uid = 'user_1',
  String displayName = 'Alice',
  bool isDeactivated = false,
}) =>
    AdminUserView(
      uid: uid,
      displayName: displayName,
      email: 'alice@example.com',
      createdAt: DateTime(2024, 1, 1),
      orderCount: 3,
      coinBalance: 1500,
      isDeactivated: isDeactivated,
      role: 'user',
    );

Map<String, dynamic> _makeSummaryDoc({
  int totalOrders = 0,
  double totalRevenue = 0,
}) =>
    {
      'today': {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'activeUsers': 5,
        'topMeals': <dynamic>[],
        'dailyOrders': <dynamic>[],
      },
      'week': {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'activeUsers': 5,
        'topMeals': <dynamic>[],
        'dailyOrders': <dynamic>[],
      },
      'month': {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'activeUsers': 5,
        'topMeals': <dynamic>[],
        'dailyOrders': <dynamic>[],
      },
    };

// ---------------------------------------------------------------------------
// 9.2 — Admin creates meal → appears in catalog
// ---------------------------------------------------------------------------

void main() {
  group('9.2 Admin creates meal → appears in catalog', () {
    test('meal list notifier reflects a newly created meal', () async {
      final fakeRepo = FakeAdminMealRepository(initial: [_makeMeal()]);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminMealRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      // Keep the auto-dispose provider alive for the duration of the test.
      final keepAlive = container.listen<AsyncValue<AdminMealState>>(
          adminMealNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      final initialState =
          await _awaitData(container, adminMealNotifierProvider);
      expect(initialState.allMeals, hasLength(1));
      expect(initialState.allMeals.first.name, equals('Jollof Rice'));

      await fakeRepo.createMeal(
          {'name': 'Egusi Soup', 'price': 4500, 'category': 'Soup'});

      final updatedState =
          await _awaitData(container, adminMealNotifierProvider);
      expect(updatedState.allMeals, hasLength(2));
      expect(updatedState.allMeals.map((m) => m.name),
          containsAll(['Jollof Rice', 'Egusi Soup']));
    });

    test('newly created meal is visible in filteredMeals with no filters',
        () async {
      final fakeRepo = FakeAdminMealRepository(initial: []);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminMealRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminMealState>>(
          adminMealNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      await _awaitData(container, adminMealNotifierProvider);

      await fakeRepo
          .createMeal({'name': 'Puff Puff', 'price': 500, 'category': 'Snacks'});

      final state = await _awaitData(container, adminMealNotifierProvider);
      expect(state.filteredMeals, hasLength(1));
      expect(state.filteredMeals.first.name, equals('Puff Puff'));
    });

    test('search filter finds newly created meal by name', () async {
      final fakeRepo = FakeAdminMealRepository(initial: [_makeMeal()]);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminMealRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminMealState>>(
          adminMealNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      await _awaitData(container, adminMealNotifierProvider);

      await fakeRepo.createMeal(
          {'name': 'Fried Plantain', 'price': 1500, 'category': 'Sides'});

      container
          .read(adminMealNotifierProvider.notifier)
          .setSearchQuery('plantain');

      final state = await _awaitData(container, adminMealNotifierProvider);
      expect(state.filteredMeals, hasLength(1));
      expect(state.filteredMeals.first.name, equals('Fried Plantain'));
    });
  });

  // ---------------------------------------------------------------------------
  // 9.3 — Admin updates order status → state reflects new status
  // ---------------------------------------------------------------------------

  group('9.3 Admin updates order status → state reflects new status', () {
    test('order status changes from pending to confirmed', () async {
      final fakeRepo = FakeAdminOrderRepository(
          initial: [_makeOrder(status: DeliveryStatus.pending)]);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminOrderRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminOrderState>>(
          adminOrderNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      final initialState =
          await _awaitData(container, adminOrderNotifierProvider);
      expect(
          initialState.allOrders.first.status, equals(DeliveryStatus.pending));

      await fakeRepo.updateOrderStatus('order_1', DeliveryStatus.confirmed);

      final updatedState =
          await _awaitData(container, adminOrderNotifierProvider);
      expect(updatedState.allOrders.first.status,
          equals(DeliveryStatus.confirmed));
    });

    test('order status changes to outForDelivery with etaMinutes', () async {
      final fakeRepo = FakeAdminOrderRepository(
          initial: [_makeOrder(status: DeliveryStatus.preparing)]);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminOrderRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminOrderState>>(
          adminOrderNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      await _awaitData(container, adminOrderNotifierProvider);

      await fakeRepo.updateOrderStatus('order_1', DeliveryStatus.outForDelivery,
          etaMinutes: 30);

      final state = await _awaitData(container, adminOrderNotifierProvider);
      expect(state.allOrders.first.status, equals(DeliveryStatus.outForDelivery));
      expect(state.allOrders.first.etaMinutes, equals(30));
    });

    test('filter by status reflects updated order', () async {
      final fakeRepo = FakeAdminOrderRepository(initial: [
        _makeOrder(orderId: 'order_1', status: DeliveryStatus.pending),
        _makeOrder(orderId: 'order_2', status: DeliveryStatus.confirmed),
      ]);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminOrderRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminOrderState>>(
          adminOrderNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      await _awaitData(container, adminOrderNotifierProvider);

      container
          .read(adminOrderNotifierProvider.notifier)
          .setStatusFilter(DeliveryStatus.confirmed);

      await fakeRepo.updateOrderStatus('order_1', DeliveryStatus.confirmed);

      final state = await _awaitData(container, adminOrderNotifierProvider);
      expect(state.filteredOrders, hasLength(2));
      expect(
          state.filteredOrders
              .every((o) => o.status == DeliveryStatus.confirmed),
          isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 9.4 — Admin deactivates user → user marked as deactivated
  // ---------------------------------------------------------------------------

  group('9.4 Admin deactivates user → user marked as deactivated', () {
    test('deactivating a user sets isDeactivated to true in state', () async {
      final fakeRepo =
          FakeAdminUserRepository(initial: [_makeUserView(isDeactivated: false)]);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminUserRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminUserState>>(
          adminUserNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      final initialState =
          await _awaitData(container, adminUserNotifierProvider);
      expect(initialState.allUsers.first.isDeactivated, isFalse);

      await container
          .read(adminUserNotifierProvider.notifier)
          .deactivateUser('user_1');

      final updatedState =
          await _awaitData(container, adminUserNotifierProvider);
      expect(updatedState.allUsers.first.isDeactivated, isTrue);
    });

    test('reactivating a user sets isDeactivated to false in state', () async {
      final fakeRepo =
          FakeAdminUserRepository(initial: [_makeUserView(isDeactivated: true)]);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminUserRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminUserState>>(
          adminUserNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      final initialState =
          await _awaitData(container, adminUserNotifierProvider);
      expect(initialState.allUsers.first.isDeactivated, isTrue);

      await container
          .read(adminUserNotifierProvider.notifier)
          .reactivateUser('user_1');

      final updatedState =
          await _awaitData(container, adminUserNotifierProvider);
      expect(updatedState.allUsers.first.isDeactivated, isFalse);
    });

    test('deactivated user appears with isDeactivated=true in list', () async {
      final fakeRepo = FakeAdminUserRepository(initial: [
        _makeUserView(uid: 'user_1', displayName: 'Alice', isDeactivated: false),
        _makeUserView(uid: 'user_2', displayName: 'Bob', isDeactivated: false),
      ]);
      addTearDown(fakeRepo.dispose);

      final container = ProviderContainer(
        overrides: [adminUserRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminUserState>>(
          adminUserNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      await _awaitData(container, adminUserNotifierProvider);

      await container
          .read(adminUserNotifierProvider.notifier)
          .deactivateUser('user_1');

      final state = await _awaitData(container, adminUserNotifierProvider);
      final alice = state.allUsers.firstWhere((u) => u.uid == 'user_1');
      final bob = state.allUsers.firstWhere((u) => u.uid == 'user_2');

      expect(alice.isDeactivated, isTrue);
      expect(bob.isDeactivated, isFalse);
    });

    test('optimistic update reverts on deactivation failure', () async {
      final fakeRepo = _ThrowingUserRepository(
          initial: [_makeUserView(isDeactivated: false)]);

      final container = ProviderContainer(
        overrides: [adminUserRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminUserState>>(
          adminUserNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      await _awaitData(container, adminUserNotifierProvider);

      await expectLater(
        container
            .read(adminUserNotifierProvider.notifier)
            .deactivateUser('user_1'),
        throwsException,
      );

      final state = await _awaitData(container, adminUserNotifierProvider);
      expect(state.allUsers.first.isDeactivated, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 9.5 — Analytics data refreshes via real-time listener
  // ---------------------------------------------------------------------------

  group('9.5 Analytics data refreshes via real-time listener', () {
    test('analytics notifier reflects updated summary from stream', () async {
      final fakeRepo = _FakeAnalyticsRepository();

      final container = ProviderContainer(
        overrides: [
          adminAnalyticsRepositoryProvider.overrideWithValue(fakeRepo)
        ],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminAnalyticsState>>(
          adminAnalyticsNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      fakeRepo.add(_makeSummaryDoc(totalOrders: 10, totalRevenue: 50000));

      final firstState =
          await _awaitData(container, adminAnalyticsNotifierProvider);
      expect(firstState.summary.totalOrders, equals(10));
      expect(firstState.summary.totalRevenue, equals(50000));

      fakeRepo.add(_makeSummaryDoc(totalOrders: 25, totalRevenue: 125000));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final secondState =
          await _awaitData(container, adminAnalyticsNotifierProvider);
      expect(secondState.summary.totalOrders, equals(25));
      expect(secondState.summary.totalRevenue, equals(125000));
    });

    test('analytics notifier delivers multiple rapid updates', () async {
      final fakeRepo = _FakeAnalyticsRepository();

      final container = ProviderContainer(
        overrides: [
          adminAnalyticsRepositoryProvider.overrideWithValue(fakeRepo)
        ],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminAnalyticsState>>(
          adminAnalyticsNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      for (var i = 1; i <= 3; i++) {
        fakeRepo.add(
            _makeSummaryDoc(totalOrders: i * 10, totalRevenue: i * 50000.0));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final state =
          await _awaitData(container, adminAnalyticsNotifierProvider);
      expect(state.summary.totalOrders, equals(30));
      expect(state.summary.totalRevenue, equals(150000));
    });

    test('analytics notifier enters error state on stream error', () async {
      final fakeRepo = _FakeAnalyticsRepository();

      final container = ProviderContainer(
        overrides: [
          adminAnalyticsRepositoryProvider.overrideWithValue(fakeRepo)
        ],
      );
      addTearDown(container.dispose);

      final keepAlive = container.listen<AsyncValue<AdminAnalyticsState>>(
          adminAnalyticsNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);

      // Give the notifier time to subscribe to the stream.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeRepo.addError(Exception('Firestore unavailable'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(adminAnalyticsNotifierProvider);
      expect(state, isA<AsyncError>());
    });
  });
}
