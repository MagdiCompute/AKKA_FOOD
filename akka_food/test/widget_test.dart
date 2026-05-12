// Smoke test for the root AkkaFoodApp widget.
//
// Verifies the app boots without throwing unhandled exceptions.
// Deep integration testing is covered by feature-specific test suites.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/delivery_system/data/datasources/notification_handler.dart';
import 'package:akka_food/main.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Fake [NotificationHandler] that does nothing — avoids Firebase dependency.
class _FakeNotificationHandler extends NotificationHandler {
  _FakeNotificationHandler()
      : super(
          messaging: _FakeFirebaseMessaging(),
          router: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const Placeholder()),
          ]),
          localNotifications: FlutterLocalNotificationsPlugin(),
          onMessageOpenedApp: const Stream.empty(),
          onMessage: const Stream.empty(),
        );

  @override
  Future<void> initialize() async {
    // No-op in tests.
  }
}

/// Minimal fake for FirebaseMessaging to satisfy the constructor.
class _FakeFirebaseMessaging extends Fake implements FirebaseMessaging {}

/// Fake CartNotifier that returns an empty cart without Hive.
class _FakeCartNotifier extends CartNotifier {
  @override
  Cart build() =>
      Cart(items: const [], deliveryOption: DeliveryOption.delivery);
}

void main() {
  testWidgets('AkkaFoodApp boots without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationHandlerProvider
              .overrideWithValue(_FakeNotificationHandler()),
          cartNotifierProvider.overrideWith(() => _FakeCartNotifier()),
        ],
        child: const AkkaFoodApp(),
      ),
    );
    // Pump a single frame — enough to verify no unhandled exceptions during
    // widget tree construction.
    await tester.pump();

    // If we reach this point, the app booted without throwing.
    // The router may redirect to /login (no auth state) or /home depending
    // on the auth guard's initial status. Either is acceptable for a smoke test.
    expect(tester.takeException(), isNull);
  });
}
