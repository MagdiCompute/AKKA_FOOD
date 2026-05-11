// integration_test/delivery_eta_test.dart
//
// Task 10.3 — Admin sets ETA → displayed in tracking screen
//
// Verifies that when an admin sets an ETA (by transitioning to outForDelivery),
// the ETA is displayed in the customer's tracking screen. Also verifies that
// ETA updates are reflected in real time.
//
// Uses a fake repository with a StreamController to simulate real-time
// Firestore behavior. No real Firebase connection needed.
//
// Satisfies Requirement 2 AC4, Requirement 4 AC5.

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

const _testOrderId = 'order-eta-test-001';

Order _testOrder({
  DeliveryStatus status = DeliveryStatus.pending,
  int? etaMinutes,
}) =>
    Order(
      id: _testOrderId,
      uid: 'uid-test',
      items: const [
        OrderItem(
          mealId: 'meal-1',
          mealName: 'Thieboudienne',
          quantity: 2,
          unitPrice: 3000.0,
        ),
      ],
      subtotal: 6000.0,
      deliveryFee: 500.0,
      discount: 0.0,
      total: 6500.0,
      deliveryOption: DeliveryOption.delivery,
      status: status,
      etaMinutes: etaMinutes,
      createdAt: DateTime(2024, 6, 15, 18, 30),
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
  // Test: ETA card NOT shown when status is preparing (Req 2 AC4)
  // ---------------------------------------------------------------------------
  testWidgets(
    'ETA card is NOT shown when order status is preparing',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTrackingApp(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Emit order with status "preparing" — no ETA set
      fakeRepo.orderController.add(
        _testOrder(status: DeliveryStatus.preparing),
      );
      await tester.pumpAndSettle();

      // ETA card should NOT be visible
      expect(find.text('Estimated Arrival'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Admin sets ETA by transitioning to outForDelivery (Req 2 AC4, Req 4 AC5)
  // ---------------------------------------------------------------------------
  testWidgets(
    'admin sets ETA → ETA card displayed when status transitions to outForDelivery',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTrackingApp(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // ── Step 1: Emit order with status "preparing" (no ETA) ───────────
      fakeRepo.orderController.add(
        _testOrder(status: DeliveryStatus.preparing),
      );
      await tester.pumpAndSettle();

      // Verify ETA card is NOT shown
      expect(find.text('Estimated Arrival'), findsNothing);
      expect(find.text('20 minutes'), findsNothing);

      // ── Step 2: Admin transitions to outForDelivery with ETA of 20 min ─
      fakeRepo.orderController.add(
        _testOrder(
          status: DeliveryStatus.outForDelivery,
          etaMinutes: 20,
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify ETA card IS shown with "20 minutes"
      expect(find.text('Estimated Arrival'), findsOneWidget);
      expect(find.text('20 minutes'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: ETA updates in real time (Req 2 AC4, Req 4 AC5)
  // ---------------------------------------------------------------------------
  testWidgets(
    'ETA card updates when admin changes ETA from 20 to 10 minutes',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTrackingApp(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // ── Step 1: Emit order with status "preparing" (no ETA) ───────────
      fakeRepo.orderController.add(
        _testOrder(status: DeliveryStatus.preparing),
      );
      await tester.pumpAndSettle();

      // Verify ETA card is NOT shown
      expect(find.text('Estimated Arrival'), findsNothing);

      // ── Step 2: Admin sets ETA to 20 minutes ──────────────────────────
      fakeRepo.orderController.add(
        _testOrder(
          status: DeliveryStatus.outForDelivery,
          etaMinutes: 20,
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify ETA card shows "20 minutes"
      expect(find.text('Estimated Arrival'), findsOneWidget);
      expect(find.text('20 minutes'), findsOneWidget);

      // ── Step 3: Admin updates ETA to 10 minutes ───────────────────────
      fakeRepo.orderController.add(
        _testOrder(
          status: DeliveryStatus.outForDelivery,
          etaMinutes: 10,
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify ETA card updates to "10 minutes"
      expect(find.text('Estimated Arrival'), findsOneWidget);
      expect(find.text('10 minutes'), findsOneWidget);
      // Old ETA should no longer be displayed
      expect(find.text('20 minutes'), findsNothing);
    },
  );
}
