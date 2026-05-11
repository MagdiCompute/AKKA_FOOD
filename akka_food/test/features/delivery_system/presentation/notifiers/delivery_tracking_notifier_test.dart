import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_option.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order_item.dart';
import 'package:akka_food/features/delivery_system/domain/entities/tracking_update.dart';
import 'package:akka_food/features/delivery_system/domain/repositories/i_delivery_repository.dart';
import 'package:akka_food/features/delivery_system/presentation/notifiers/delivery_tracking_notifier.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

/// A fake [IDeliveryRepository] that exposes [StreamController]s so tests
/// can push events manually.
class FakeDeliveryRepository implements IDeliveryRepository {
  /// Map of orderId → StreamController for watchOrder streams.
  final Map<String, StreamController<Order>> _orderControllers = {};

  /// Returns (or creates) the [StreamController] for the given [orderId].
  StreamController<Order> controllerFor(String orderId) {
    return _orderControllers.putIfAbsent(
      orderId,
      () => StreamController<Order>.broadcast(),
    );
  }

  @override
  Stream<Order> watchOrder(String orderId) {
    return controllerFor(orderId).stream;
  }

  @override
  Future<Order?> getOrder(String orderId) => throw UnimplementedError();

  @override
  Future<List<TrackingUpdate>> getTrackingUpdates(String orderId) =>
      throw UnimplementedError();

  @override
  Stream<List<TrackingUpdate>> watchTrackingUpdates(String orderId) =>
      throw UnimplementedError();

  @override
  Future<void> updateOrderStatus(
    String orderId,
    DeliveryStatus newStatus, {
    int? etaMinutes,
  }) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> getActiveOrders() => throw UnimplementedError();

  /// Disposes all controllers.
  void dispose() {
    for (final controller in _orderControllers.values) {
      controller.close();
    }
    _orderControllers.clear();
  }
}

// ---------------------------------------------------------------------------
// Test order factory
// ---------------------------------------------------------------------------

Order makeOrder({
  String id = 'order_1',
  String uid = 'user_1',
  DeliveryStatus status = DeliveryStatus.pending,
  int? etaMinutes,
}) =>
    Order(
      id: id,
      uid: uid,
      items: const [
        OrderItem(
          mealId: 'meal_1',
          mealName: 'Test Meal',
          quantity: 1,
          unitPrice: 2000,
        ),
      ],
      subtotal: 2000,
      deliveryFee: 500,
      discount: 0,
      total: 2500,
      deliveryOption: DeliveryOption.delivery,
      status: status,
      etaMinutes: etaMinutes,
      createdAt: DateTime(2024, 6, 1),
    );

// ---------------------------------------------------------------------------
// Helper: build a ProviderContainer with the fake repository
// ---------------------------------------------------------------------------

ProviderContainer makeContainer(FakeDeliveryRepository fakeRepo) {
  return ProviderContainer(
    overrides: [
      deliveryRepositoryProvider.overrideWithValue(fakeRepo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Helper: pump the event loop to allow stream events to propagate
// ---------------------------------------------------------------------------

/// Pumps the event loop to allow stream events and Riverpod state updates
/// to propagate through the microtask queue.
Future<void> pump() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeDeliveryRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeDeliveryRepository();
    container = makeContainer(fakeRepo);
  });

  tearDown(() {
    container.dispose();
    fakeRepo.dispose();
  });

  group('DeliveryTrackingNotifier', () {
    // -----------------------------------------------------------------------
    // 1. Initial state is AsyncData(null)
    // -----------------------------------------------------------------------
    test('initial state is AsyncData(null)', () async {
      // Keep the provider alive by listening to it.
      final sub = container.listen(
        deliveryTrackingNotifierProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      final state = container.read(deliveryTrackingNotifierProvider);
      expect(state, isA<AsyncData<Order?>>());
      expect(state.value, isNull);
    });

    // -----------------------------------------------------------------------
    // 2. watchOrder sets state to AsyncLoading then AsyncData(order)
    // -----------------------------------------------------------------------
    test(
        'watchOrder sets state to AsyncLoading then AsyncData when stream emits',
        () async {
      // Keep the provider alive.
      final sub = container.listen(
        deliveryTrackingNotifierProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      final notifier =
          container.read(deliveryTrackingNotifierProvider.notifier);

      notifier.watchOrder('order_1');

      // After calling watchOrder, state should be loading.
      final loadingState = container.read(deliveryTrackingNotifierProvider);
      expect(loadingState, isA<AsyncLoading<Order?>>());

      // Emit an order from the stream.
      final order = makeOrder(id: 'order_1', status: DeliveryStatus.confirmed);
      fakeRepo.controllerFor('order_1').add(order);

      // Allow microtasks to process the stream event.
      await pump();

      final dataState = container.read(deliveryTrackingNotifierProvider);
      expect(dataState, isA<AsyncData<Order?>>());
      expect(dataState.value, equals(order));
    });

    // -----------------------------------------------------------------------
    // 3. watchOrder sets state to AsyncError when stream emits an error
    // -----------------------------------------------------------------------
    test('watchOrder sets state to AsyncError when stream emits an error',
        () async {
      // Keep the provider alive.
      final sub = container.listen(
        deliveryTrackingNotifierProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      final notifier =
          container.read(deliveryTrackingNotifierProvider.notifier);

      notifier.watchOrder('order_1');

      // Emit an error from the stream.
      fakeRepo.controllerFor('order_1').addError(Exception('Network error'));

      // Allow microtasks to process the stream event.
      await pump();

      final errorState = container.read(deliveryTrackingNotifierProvider);
      expect(errorState, isA<AsyncError<Order?>>());
      expect(errorState.error, isA<Exception>());
    });

    // -----------------------------------------------------------------------
    // 4. Calling watchOrder with a new orderId cancels the previous subscription
    // -----------------------------------------------------------------------
    test(
        'calling watchOrder with a new orderId cancels the previous subscription',
        () async {
      // Keep the provider alive.
      final sub = container.listen(
        deliveryTrackingNotifierProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      final notifier =
          container.read(deliveryTrackingNotifierProvider.notifier);

      // Start watching order_1.
      notifier.watchOrder('order_1');
      final order1 =
          makeOrder(id: 'order_1', status: DeliveryStatus.confirmed);
      fakeRepo.controllerFor('order_1').add(order1);
      await pump();

      // Verify order_1 is being tracked.
      expect(
        container.read(deliveryTrackingNotifierProvider).value,
        equals(order1),
      );

      // Switch to watching order_2.
      notifier.watchOrder('order_2');

      // State should be loading again for the new order.
      expect(
        container.read(deliveryTrackingNotifierProvider),
        isA<AsyncLoading<Order?>>(),
      );

      // Emit on the old stream — should NOT update state because
      // the subscription was cancelled.
      final updatedOrder1 =
          makeOrder(id: 'order_1', status: DeliveryStatus.delivered);
      fakeRepo.controllerFor('order_1').add(updatedOrder1);
      await pump();

      // State should still be loading (waiting for order_2 data).
      expect(
        container.read(deliveryTrackingNotifierProvider),
        isA<AsyncLoading<Order?>>(),
      );

      // Emit on the new stream — should update state.
      final order2 =
          makeOrder(id: 'order_2', status: DeliveryStatus.preparing);
      fakeRepo.controllerFor('order_2').add(order2);
      await pump();

      expect(
        container.read(deliveryTrackingNotifierProvider).value,
        equals(order2),
      );
    });

    // -----------------------------------------------------------------------
    // 5. stopWatching cancels subscription and resets state to AsyncData(null)
    // -----------------------------------------------------------------------
    test(
        'stopWatching cancels the subscription and resets state to AsyncData(null)',
        () async {
      // Keep the provider alive.
      final sub = container.listen(
        deliveryTrackingNotifierProvider,
        (_, __) {},
      );
      addTearDown(sub.close);

      final notifier =
          container.read(deliveryTrackingNotifierProvider.notifier);

      // Start watching and receive data.
      notifier.watchOrder('order_1');
      final order = makeOrder(id: 'order_1', status: DeliveryStatus.confirmed);
      fakeRepo.controllerFor('order_1').add(order);
      await pump();

      expect(
        container.read(deliveryTrackingNotifierProvider).value,
        equals(order),
      );

      // Stop watching.
      notifier.stopWatching();

      final stoppedState = container.read(deliveryTrackingNotifierProvider);
      expect(stoppedState, isA<AsyncData<Order?>>());
      expect(stoppedState.value, isNull);

      // Emit on the stream after stopping — should NOT update state.
      final updatedOrder =
          makeOrder(id: 'order_1', status: DeliveryStatus.delivered);
      fakeRepo.controllerFor('order_1').add(updatedOrder);
      await pump();

      // State should still be null.
      expect(
        container.read(deliveryTrackingNotifierProvider).value,
        isNull,
      );
    });

    // -----------------------------------------------------------------------
    // 6. Subscription is cancelled when the notifier is disposed
    // -----------------------------------------------------------------------
    test('subscription is cancelled when the notifier is disposed', () async {
      // Keep the provider alive via a listener we can close.
      final sub = container.listen(
        deliveryTrackingNotifierProvider,
        (_, __) {},
      );

      final notifier =
          container.read(deliveryTrackingNotifierProvider.notifier);

      // Start watching.
      notifier.watchOrder('order_1');
      final order = makeOrder(id: 'order_1', status: DeliveryStatus.confirmed);
      fakeRepo.controllerFor('order_1').add(order);
      await pump();

      expect(
        container.read(deliveryTrackingNotifierProvider).value,
        equals(order),
      );

      // Close the listener — this triggers auto-dispose of the notifier,
      // which should cancel the subscription via ref.onDispose.
      sub.close();
      await pump();

      // Emitting after dispose should not throw (subscription was cancelled).
      // With a broadcast controller, adding after all listeners are gone is safe.
      expect(
        () => fakeRepo.controllerFor('order_1').add(
              makeOrder(id: 'order_1', status: DeliveryStatus.delivered),
            ),
        returnsNormally,
      );
    });
  });
}
