import 'dart:async';

import 'package:akka_food/features/delivery_system/data/datasources/notification_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('NotificationHandler', () {
    late FakeFirebaseMessagingForNotification fakeMessaging;
    late FakeGoRouter fakeRouter;
    late FlutterLocalNotificationsPlugin fakeLocalNotifications;
    late StreamController<RemoteMessage> onMessageOpenedAppController;
    late StreamController<RemoteMessage> onMessageController;
    late NotificationHandler handler;

    setUp(() {
      fakeMessaging = FakeFirebaseMessagingForNotification();
      fakeRouter = FakeGoRouter();
      fakeLocalNotifications = FlutterLocalNotificationsPlugin();
      onMessageOpenedAppController =
          StreamController<RemoteMessage>.broadcast();
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

    group('initialize - cold start', () {
      test('navigates to order tracking when initial message has orderId',
          () async {
        fakeMessaging.initialMessage = RemoteMessage(
          data: const {
            'orderId': 'order-123',
            'status': 'out_for_delivery',
            'type': 'order_status_update',
          },
        );

        await handler.initialize();

        expect(fakeRouter.pushedPaths, contains('/orders/order-123/tracking'));
      });

      test('does not navigate when initial message is null', () async {
        fakeMessaging.initialMessage = null;

        await handler.initialize();

        expect(fakeRouter.pushedPaths, isEmpty);
      });

      test('does not navigate when initial message has no orderId', () async {
        fakeMessaging.initialMessage = const RemoteMessage(
          data: {'status': 'delivered', 'type': 'order_status_update'},
        );

        await handler.initialize();

        expect(fakeRouter.pushedPaths, isEmpty);
      });

      test('does not navigate when orderId is empty', () async {
        fakeMessaging.initialMessage = const RemoteMessage(
          data: {
            'orderId': '',
            'status': 'delivered',
            'type': 'order_status_update',
          },
        );

        await handler.initialize();

        expect(fakeRouter.pushedPaths, isEmpty);
      });
    });

    group('initialize - background tap', () {
      test('navigates to order tracking when background notification is tapped',
          () async {
        await handler.initialize();

        // Simulate a background notification tap
        onMessageOpenedAppController.add(RemoteMessage(
          data: const {
            'orderId': 'order-456',
            'status': 'delivered',
            'type': 'order_status_update',
          },
        ));

        // Allow the stream listener to process
        await Future<void>.delayed(Duration.zero);

        expect(fakeRouter.pushedPaths, contains('/orders/order-456/tracking'));
      });

      test('does not navigate when background message has no orderId',
          () async {
        await handler.initialize();

        onMessageOpenedAppController.add(const RemoteMessage(
          data: {'status': 'delivered', 'type': 'order_status_update'},
        ));

        await Future<void>.delayed(Duration.zero);

        expect(fakeRouter.pushedPaths, isEmpty);
      });

      test('handles multiple background notification taps', () async {
        await handler.initialize();

        onMessageOpenedAppController.add(RemoteMessage(
          data: const {
            'orderId': 'order-aaa',
            'status': 'confirmed',
            'type': 'order_status_update',
          },
        ));
        await Future<void>.delayed(Duration.zero);

        onMessageOpenedAppController.add(RemoteMessage(
          data: const {
            'orderId': 'order-bbb',
            'status': 'out_for_delivery',
            'type': 'order_status_update',
          },
        ));
        await Future<void>.delayed(Duration.zero);

        expect(fakeRouter.pushedPaths, [
          '/orders/order-aaa/tracking',
          '/orders/order-bbb/tracking',
        ]);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class FakeFirebaseMessagingForNotification extends Fake
    implements FirebaseMessaging {
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

/// A fake GoRouter that records pushed paths for verification.
class FakeGoRouter extends Fake implements GoRouter {
  final List<String> pushedPaths = [];

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async {
    pushedPaths.add(location);
    return null;
  }
}
