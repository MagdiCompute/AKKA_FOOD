// integration_test/delivery_notification_test.dart
//
// Task 10.2 — Push notification sent on status change
//
// Verifies that when a foreground FCM message arrives with an order status
// update, the NotificationHandler shows an in-app SnackBar with the correct
// title, body, and a "View" action that navigates to the OrderTrackingScreen.
//
// The server-side push notification logic (Cloud Function sending FCM) is
// covered by functions/src/delivery/onOrderStatusChanged.test.ts and
// functions/src/helpers/sendOrderStatusNotification.test.ts.
//
// This integration test covers the Flutter client-side behavior:
// - Foreground message received → in-app SnackBar displayed
// - SnackBar shows correct notification title and body
// - "View" action navigates to the correct OrderTrackingScreen route
// - Non-order messages are ignored (no SnackBar shown)
// - Messages without orderId do not show a "View" action
//
// Satisfies Requirement 3 AC1 (client-side notification display).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/delivery_system/data/datasources/notification_handler.dart';

// =============================================================================
// Test doubles
// =============================================================================

/// Fake FirebaseMessaging that allows controlling foreground message streams.
class FakeFirebaseMessagingForTest extends Fake implements FirebaseMessaging {
  RemoteMessage? initialMessage;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {}
}

/// A GoRouter that records pushed paths for verification.
class RecordingGoRouter extends Fake implements GoRouter {
  final List<String> pushedPaths = [];

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async {
    pushedPaths.add(location);
    return null;
  }
}

// =============================================================================
// Helper — builds a minimal app with NotificationHandler wired up
// =============================================================================

Widget _buildNotificationTestApp({
  required NotificationHandler handler,
}) {
  return ProviderScope(
    child: MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: const Scaffold(
        body: Center(child: Text('Home Screen')),
      ),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseMessagingForTest fakeMessaging;
  late RecordingGoRouter fakeRouter;
  late FlutterLocalNotificationsPlugin fakeLocalNotifications;
  late StreamController<RemoteMessage> onMessageOpenedAppController;
  late StreamController<RemoteMessage> onMessageController;
  late NotificationHandler handler;

  setUp(() {
    fakeMessaging = FakeFirebaseMessagingForTest();
    fakeRouter = RecordingGoRouter();
    fakeLocalNotifications = FlutterLocalNotificationsPlugin();
    onMessageOpenedAppController = StreamController<RemoteMessage>.broadcast();
    onMessageController = StreamController<RemoteMessage>.broadcast();

    handler = NotificationHandler(
      messaging: fakeMessaging,
      router: fakeRouter,
      localNotifications: fakeLocalNotifications,
      onMessageOpenedApp: onMessageOpenedAppController.stream,
      onMessage: onMessageController.stream,
    );
  });

  tearDown(() {
    handler.dispose();
    onMessageOpenedAppController.close();
    onMessageController.close();
  });

  // ---------------------------------------------------------------------------
  // Test: Foreground notification shows in-app SnackBar for "out_for_delivery"
  // ---------------------------------------------------------------------------
  testWidgets(
    'foreground notification: out_for_delivery shows SnackBar with ETA',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildNotificationTestApp(handler: handler));
      await handler.initialize();
      await tester.pumpAndSettle();

      // Simulate a foreground FCM message for "out_for_delivery"
      onMessageController.add(RemoteMessage(
        notification: const RemoteNotification(
          title: 'Your order is on the way!',
          body: 'ETA: 15 minutes',
        ),
        data: const {
          'orderId': 'order-notif-001',
          'status': 'out_for_delivery',
          'type': 'order_status_update',
        },
      ));

      await tester.pumpAndSettle();

      // Verify SnackBar is shown with correct content
      expect(find.text('Your order is on the way!'), findsOneWidget);
      expect(find.text('ETA: 15 minutes'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Foreground notification shows in-app SnackBar for "delivered"
  // ---------------------------------------------------------------------------
  testWidgets(
    'foreground notification: delivered shows SnackBar with delivery message',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildNotificationTestApp(handler: handler));
      await handler.initialize();
      await tester.pumpAndSettle();

      // Simulate a foreground FCM message for "delivered"
      onMessageController.add(RemoteMessage(
        notification: const RemoteNotification(
          title: 'Order delivered!',
          body: 'Tap to rate your experience',
        ),
        data: const {
          'orderId': 'order-notif-002',
          'status': 'delivered',
          'type': 'order_status_update',
        },
      ));

      await tester.pumpAndSettle();

      // Verify SnackBar is shown with correct content
      expect(find.text('Order delivered!'), findsOneWidget);
      expect(find.text('Tap to rate your experience'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Foreground notification shows in-app SnackBar for "failed"
  // ---------------------------------------------------------------------------
  testWidgets(
    'foreground notification: failed shows SnackBar with failure message',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildNotificationTestApp(handler: handler));
      await handler.initialize();
      await tester.pumpAndSettle();

      // Simulate a foreground FCM message for "failed"
      onMessageController.add(RemoteMessage(
        notification: const RemoteNotification(
          title: 'Delivery issue',
          body: "We couldn't deliver your order. We'll contact you shortly.",
        ),
        data: const {
          'orderId': 'order-notif-003',
          'status': 'failed',
          'type': 'order_status_update',
        },
      ));

      await tester.pumpAndSettle();

      // Verify SnackBar is shown with correct content
      expect(find.text('Delivery issue'), findsOneWidget);
      expect(
        find.text(
            "We couldn't deliver your order. We'll contact you shortly."),
        findsOneWidget,
      );
      expect(find.text('View'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: "View" action navigates to OrderTrackingScreen
  // ---------------------------------------------------------------------------
  testWidgets(
    'foreground notification: tapping "View" navigates to order tracking',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildNotificationTestApp(handler: handler));
      await handler.initialize();
      await tester.pumpAndSettle();

      // Simulate a foreground FCM message
      onMessageController.add(RemoteMessage(
        notification: const RemoteNotification(
          title: 'Order confirmed',
          body: 'Your order has been confirmed!',
        ),
        data: const {
          'orderId': 'order-nav-001',
          'status': 'confirmed',
          'type': 'order_status_update',
        },
      ));

      await tester.pumpAndSettle();

      // Tap the "View" action on the SnackBar
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      // Verify navigation to the correct order tracking route
      expect(
        fakeRouter.pushedPaths,
        contains('/orders/order-nav-001/tracking'),
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Non-order messages are ignored (no SnackBar)
  // ---------------------------------------------------------------------------
  testWidgets(
    'foreground notification: non-order messages are ignored',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildNotificationTestApp(handler: handler));
      await handler.initialize();
      await tester.pumpAndSettle();

      // Simulate a foreground FCM message with a different type
      onMessageController.add(RemoteMessage(
        notification: const RemoteNotification(
          title: 'Promo Alert',
          body: '50% off today!',
        ),
        data: const {
          'type': 'promo',
        },
      ));

      await tester.pumpAndSettle();

      // Verify no SnackBar is shown
      expect(find.text('Promo Alert'), findsNothing);
      expect(find.text('50% off today!'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Message without orderId shows SnackBar but no "View" action
  // ---------------------------------------------------------------------------
  testWidgets(
    'foreground notification: message without orderId shows no View action',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildNotificationTestApp(handler: handler));
      await handler.initialize();
      await tester.pumpAndSettle();

      // Simulate a foreground FCM message without orderId
      onMessageController.add(RemoteMessage(
        notification: const RemoteNotification(
          title: 'Order Update',
          body: 'Status changed',
        ),
        data: const {
          'status': 'confirmed',
          'type': 'order_status_update',
        },
      ));

      await tester.pumpAndSettle();

      // SnackBar should show the title but no "View" action
      expect(find.text('Order Update'), findsOneWidget);
      expect(find.text('View'), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Background tap navigates to order tracking (Req 3 AC2 deep link)
  // ---------------------------------------------------------------------------
  testWidgets(
    'background notification tap: navigates to order tracking screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildNotificationTestApp(handler: handler));
      await handler.initialize();
      await tester.pumpAndSettle();

      // Simulate a background notification tap
      onMessageOpenedAppController.add(RemoteMessage(
        data: const {
          'orderId': 'order-bg-001',
          'status': 'out_for_delivery',
          'type': 'order_status_update',
        },
      ));

      await tester.pumpAndSettle();

      // Verify navigation to the correct order tracking route
      expect(
        fakeRouter.pushedPaths,
        contains('/orders/order-bg-001/tracking'),
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Cold start with initial message navigates to order tracking
  // ---------------------------------------------------------------------------
  testWidgets(
    'cold start notification: navigates to order tracking screen',
    (WidgetTester tester) async {
      // Set up initial message before initialization
      fakeMessaging.initialMessage = RemoteMessage(
        data: const {
          'orderId': 'order-cold-001',
          'status': 'delivered',
          'type': 'order_status_update',
        },
      );

      await tester.pumpWidget(_buildNotificationTestApp(handler: handler));
      await handler.initialize();
      await tester.pumpAndSettle();

      // Verify navigation to the correct order tracking route
      expect(
        fakeRouter.pushedPaths,
        contains('/orders/order-cold-001/tracking'),
      );
    },
  );
}
