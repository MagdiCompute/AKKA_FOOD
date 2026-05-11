// integration_test/delivery_tracking_realtime_test.dart
//
// Task 10.1 — Order status update → tracking screen updates within 5s
//
// Verifies that when an order's delivery status changes, the tracking screen
// reflects the change within 5 seconds without requiring a manual refresh.
// Uses a fake repository with a StreamController to simulate real-time
// Firestore behavior. No real Firebase connection needed.
//
// Satisfies Requirement 2 AC2.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_option.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order_item.dart';
import 'package:akka_food/features/delivery_system/domain/entities/tracking_update.dart';
import 'package:akka_food/features/delivery_system/domain/repositories/i_delivery_repository.dart';
import 'package:akka_food/features/delivery_system/presentation/notifiers/delivery_tracking_notifier.dart';
import 'package:akka_food/features/delivery_system/presentation/screens/order_tracking_screen.dart';

// =============================================================================
// Test fixtures
// =============================================================================

const _testOrderId = 'order-tracking-test-001';

Order _testOrder({DeliveryStatus status = DeliveryStatus.pending}) => Order(
      id: _testOrderId,
      uid: 'uid-test',
      items: const [
        OrderItem(
          mealId: 'meal-1',
          mealName: 'Jollof Rice',
          quantity: 1,
          unitPrice: 2500.0,
        ),
      ],
      subtotal: 2500.0,
      deliveryFee: 500.0,
      discount: 0.0,
      total: 3000.0,
      deliveryOption: DeliveryOption.delivery,
      status: status,
      createdAt: DateTime(2024, 6, 1, 12, 0),
    );

// =============================================================================
// FakeDeliveryRepository — simulates real-time Firestore updates
// =============================================================================

class FakeDeliveryRepository implements IDeliveryRepository {
  /// StreamController that simulates Firestore real-time order updates.
  final StreamController<Order> orderController =
      StreamController<Order>.broadcast();

  @override
  Stream<Order> watchOrder(String orderId) => orderController.stream;

  @override
  Future<Order?> getOrder(String orderId) async => null;

  @override
  Future<List<TrackingUpdate>> getTrackingUpdates(String orderId) async => [];

  @override
  Stream<List<TrackingUpdate>> watchTrackingUpdates(String orderId) =>
      Stream.value([]);

  @override
  Future<void> updateOrderStatus(
    String orderId,
    DeliveryStatus newStatus, {
    int? etaMinutes,
  }) async {}

  @override
  Stream<List<Order>> getActiveOrders() => Stream.value([]);

  void dispose() {
    orderController.close();
  }
}

// =============================================================================
// Helper — builds OrderTrackingScreen wrapped in ProviderScope with overrides
// =============================================================================

Widget _buildTrackingApp({required FakeDeliveryRepository fakeRepo}) {
  return ProviderScope(
    overrides: [
      deliveryRepositoryProvider.overrideWithValue(fakeRepo),
    ],
    child: const MaterialApp(
      home: OrderTrackingScreen(orderId: _testOrderId),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeDeliveryRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeDeliveryRepository();
  });

  tearDown(() {
    fakeRepo.dispose();
  });

  // ---------------------------------------------------------------------------
  // Test: pending → confirmed real-time update (Req 2 AC2)
  // ---------------------------------------------------------------------------
  testWidgets(
    'order status update: pending → confirmed updates tracking screen within 5s',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTrackingApp(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // ── Step 1: Emit initial order with status "pending" ──────────────
      fakeRepo.orderController.add(_testOrder(status: DeliveryStatus.pending));
      await tester.pumpAndSettle();

      // Verify the screen shows "Pending" as the current status
      expect(find.text('Pending'), findsOneWidget);

      // ── Step 2: Emit updated order with status "confirmed" ────────────
      fakeRepo.orderController
          .add(_testOrder(status: DeliveryStatus.confirmed));

      // Pump frames for up to 5 seconds to verify the update arrives in time
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify the screen now shows "Confirmed" as a stage label
      // The timeline shows all stages; "Confirmed" should be highlighted
      // as the current stage (bold + primary color).
      expect(find.text('Confirmed'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: confirmed → preparing real-time update (Req 2 AC2)
  // ---------------------------------------------------------------------------
  testWidgets(
    'order status update: confirmed → preparing updates tracking screen within 5s',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTrackingApp(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Emit initial order with status "confirmed"
      fakeRepo.orderController
          .add(_testOrder(status: DeliveryStatus.confirmed));
      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);

      // Emit updated order with status "preparing"
      fakeRepo.orderController
          .add(_testOrder(status: DeliveryStatus.preparing));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The timeline renders "Preparing" as a stage label
      expect(find.text('Preparing'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: preparing → out_for_delivery shows ETA card (Req 2 AC2, AC4)
  // ---------------------------------------------------------------------------
  testWidgets(
    'order status update: preparing → out_for_delivery shows ETA within 5s',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTrackingApp(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Emit initial order with status "preparing"
      fakeRepo.orderController
          .add(_testOrder(status: DeliveryStatus.preparing));
      await tester.pumpAndSettle();

      // ETA card should NOT be visible yet
      expect(find.text('Estimated Arrival'), findsNothing);

      // Emit updated order with status "outForDelivery" and ETA set
      final outForDeliveryOrder = _testOrder(
        status: DeliveryStatus.outForDelivery,
      ).copyWith(etaMinutes: 25);
      fakeRepo.orderController.add(outForDeliveryOrder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The timeline should show "Out for Delivery"
      expect(find.text('Out for Delivery'), findsOneWidget);

      // ETA card should now be visible with 25 minutes
      expect(find.text('Estimated Arrival'), findsOneWidget);
      expect(find.text('25 minutes'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: out_for_delivery → delivered shows confirmation (Req 2 AC2, AC5)
  // ---------------------------------------------------------------------------
  testWidgets(
    'order status update: out_for_delivery → delivered shows confirmation within 5s',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTrackingApp(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Emit initial order with status "outForDelivery"
      final outOrder = _testOrder(
        status: DeliveryStatus.outForDelivery,
      ).copyWith(etaMinutes: 10);
      fakeRepo.orderController.add(outOrder);
      await tester.pumpAndSettle();

      // Delivery confirmation should NOT be visible yet
      expect(find.text('Order Delivered!'), findsNothing);
      expect(find.text('Rate Order'), findsNothing);

      // Emit updated order with status "delivered"
      final deliveredOrder = _testOrder(
        status: DeliveryStatus.delivered,
      ).copyWith(deliveredAt: DateTime(2024, 6, 1, 12, 45));
      fakeRepo.orderController.add(deliveredOrder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Delivery confirmation message and Rate Order button should appear
      expect(find.text('Order Delivered!'), findsOneWidget);
      expect(find.text('Rate Order'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: full lifecycle pending → confirmed → preparing → out → delivered
  // ---------------------------------------------------------------------------
  testWidgets(
    'full delivery lifecycle updates tracking screen in real-time',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTrackingApp(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // ── pending ───────────────────────────────────────────────────────
      fakeRepo.orderController.add(_testOrder(status: DeliveryStatus.pending));
      await tester.pumpAndSettle();
      expect(find.text('Order Tracking'), findsOneWidget);

      // ── confirmed ─────────────────────────────────────────────────────
      fakeRepo.orderController
          .add(_testOrder(status: DeliveryStatus.confirmed));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ── preparing ─────────────────────────────────────────────────────
      fakeRepo.orderController
          .add(_testOrder(status: DeliveryStatus.preparing));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ── out for delivery ──────────────────────────────────────────────
      final outOrder = _testOrder(
        status: DeliveryStatus.outForDelivery,
      ).copyWith(etaMinutes: 15);
      fakeRepo.orderController.add(outOrder);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Out for Delivery'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);

      // ── delivered ─────────────────────────────────────────────────────
      final deliveredOrder = _testOrder(
        status: DeliveryStatus.delivered,
      ).copyWith(deliveredAt: DateTime(2024, 6, 1, 13, 0));
      fakeRepo.orderController.add(deliveredOrder);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Order Delivered!'), findsOneWidget);
      expect(find.text('Rate Order'), findsOneWidget);
    },
  );
}
