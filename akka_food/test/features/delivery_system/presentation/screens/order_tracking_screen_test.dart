import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_option.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order_item.dart';
import 'package:akka_food/features/delivery_system/domain/entities/tracking_update.dart';
import 'package:akka_food/features/delivery_system/domain/repositories/i_delivery_repository.dart';
import 'package:akka_food/features/delivery_system/presentation/notifiers/delivery_tracking_notifier.dart';
import 'package:akka_food/features/delivery_system/presentation/screens/order_tracking_screen.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeDeliveryRepository implements IDeliveryRepository {
  final Map<String, StreamController<Order>> _orderControllers = {};

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
  String? failureReason,
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
      failureReason: failureReason,
      createdAt: DateTime(2024, 6, 1),
    );

// ---------------------------------------------------------------------------
// Helper: pump the widget with overrides
// ---------------------------------------------------------------------------

Widget buildTestWidget({
  required FakeDeliveryRepository fakeRepo,
  String orderId = 'order_1',
}) {
  return ProviderScope(
    overrides: [
      deliveryRepositoryProvider.overrideWithValue(fakeRepo),
    ],
    child: MaterialApp(
      home: OrderTrackingScreen(orderId: orderId),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeDeliveryRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeDeliveryRepository();
  });

  tearDown(() {
    fakeRepo.dispose();
  });

  group('OrderTrackingScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump(); // trigger initState post-frame callback

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry button on stream error',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump(); // trigger initState

      // Emit an error
      fakeRepo.controllerFor('order_1').addError(Exception('Network error'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Unable to load order tracking'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows tracking content when order data arrives',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump(); // trigger initState

      // Emit order data
      fakeRepo.controllerFor('order_1').add(
        makeOrder(status: DeliveryStatus.preparing),
      );
      await tester.pump();
      await tester.pump();

      // Should show the order ID
      expect(find.text('Order #order_1'), findsOneWidget);
      // Should show the timeline
      expect(find.text('Delivery Status'), findsOneWidget);
      // Should show timeline stages
      expect(find.text('Preparing'), findsOneWidget);
    });

    testWidgets('shows ETA card when status is outForDelivery',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump();

      fakeRepo.controllerFor('order_1').add(
        makeOrder(status: DeliveryStatus.outForDelivery, etaMinutes: 15),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Estimated Arrival'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);
    });

    testWidgets('hides ETA card when etaMinutes is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump();

      fakeRepo.controllerFor('order_1').add(
        makeOrder(status: DeliveryStatus.outForDelivery, etaMinutes: null),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Estimated Arrival'), findsNothing);
    });

    testWidgets(
        'shows delivery confirmation and Rate Order button when delivered',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump();

      fakeRepo.controllerFor('order_1').add(
        makeOrder(status: DeliveryStatus.delivered),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Order Delivered!'), findsOneWidget);
      expect(find.text('Rate Order'), findsOneWidget);
    });

    testWidgets('shows failure info when status is failed', (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump();

      fakeRepo.controllerFor('order_1').add(
        makeOrder(
          status: DeliveryStatus.failed,
          failureReason: 'Address not found',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Delivery Failed'), findsOneWidget);
      expect(find.text('Address not found'), findsOneWidget);
    });

    testWidgets('updates UI in real-time when status changes', (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump();

      // First emit: pending
      fakeRepo.controllerFor('order_1').add(
        makeOrder(status: DeliveryStatus.pending),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Order #order_1'), findsOneWidget);
      expect(find.text('Order Delivered!'), findsNothing);

      // Second emit: delivered
      fakeRepo.controllerFor('order_1').add(
        makeOrder(status: DeliveryStatus.delivered),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Order Delivered!'), findsOneWidget);
      expect(find.text('Rate Order'), findsOneWidget);
    });

    testWidgets('retry button re-watches the order', (tester) async {
      await tester.pumpWidget(buildTestWidget(fakeRepo: fakeRepo));
      await tester.pump();

      // Emit an error
      fakeRepo.controllerFor('order_1').addError(Exception('Network error'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Should show loading again
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
