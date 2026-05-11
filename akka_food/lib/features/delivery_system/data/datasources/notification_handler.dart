import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/router/app_router.dart';
import 'fcm_service.dart';

part 'notification_handler.g.dart';

/// Global scaffold messenger key used to show in-app SnackBars from anywhere.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Handles push notification taps and foreground notifications.
///
/// Covers three scenarios:
/// - **Background tap**: App is in background, user taps notification →
///   `FirebaseMessaging.onMessageOpenedApp` fires.
/// - **Cold start**: App was terminated, user taps notification →
///   `FirebaseMessaging.instance.getInitialMessage()` returns the message.
/// - **Foreground**: App is in foreground, push notification arrives →
///   Shows a local notification (tray) and an in-app SnackBar with a "View"
///   action that navigates to the OrderTrackingScreen.
///
/// The notification data payload is expected to contain:
/// ```json
/// { "orderId": "...", "status": "...", "type": "order_status_update" }
/// ```
class NotificationHandler {
  NotificationHandler({
    required FirebaseMessaging messaging,
    required GoRouter router,
    required FlutterLocalNotificationsPlugin localNotifications,
    Stream<RemoteMessage>? onMessageOpenedApp,
    Stream<RemoteMessage>? onMessage,
  })  : _messaging = messaging,
        _router = router,
        _localNotifications = localNotifications,
        _onMessageOpenedApp =
            onMessageOpenedApp ?? FirebaseMessaging.onMessageOpenedApp,
        _onMessage = onMessage ?? FirebaseMessaging.onMessage;

  final FirebaseMessaging _messaging;
  final GoRouter _router;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Stream<RemoteMessage> _onMessageOpenedApp;
  final Stream<RemoteMessage> _onMessage;

  StreamSubscription<RemoteMessage>? _messageOpenedAppSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  /// Notification ID counter for local notifications.
  int _notificationId = 0;

  /// Initializes notification handling for background, cold start, and
  /// foreground scenarios.
  Future<void> initialize() async {
    // Configure iOS foreground notification presentation.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle cold start: app was terminated when notification was tapped.
    await _handleInitialMessage();

    // Handle background tap: app was in background when notification was tapped.
    _listenForMessageOpenedApp();

    // Handle foreground messages: show local notification + in-app banner.
    _listenForForegroundMessages();
  }

  /// Cancels all notification listeners.
  void dispose() {
    _messageOpenedAppSub?.cancel();
    _foregroundMessageSub?.cancel();
  }

  /// Checks if the app was opened from a terminated state via a notification.
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage);
    }
  }

  /// Listens for notification taps when the app is in the background.
  void _listenForMessageOpenedApp() {
    _messageOpenedAppSub =
        _onMessageOpenedApp.listen(_handleNotificationNavigation);
  }

  /// Listens for messages received while the app is in the foreground.
  ///
  /// When a foreground message arrives with `type: "order_status_update"`:
  /// 1. Shows a local notification in the system tray (Android).
  /// 2. Shows an in-app SnackBar with a "View" action.
  void _listenForForegroundMessages() {
    _foregroundMessageSub = _onMessage.listen(_handleForegroundMessage);
  }

  /// Handles a foreground message by showing a local notification and an
  /// in-app SnackBar.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] as String?;

    // Only handle order status update notifications.
    if (type != 'order_status_update') return;

    final title = message.notification?.title ?? 'Order Update';
    final body = message.notification?.body ?? '';
    final orderId = data['orderId'] as String?;

    // Show local notification in the system tray (primarily for Android).
    await _showLocalNotification(title: title, body: body, orderId: orderId);

    // Show in-app SnackBar with a "View" action.
    _showInAppSnackBar(title: title, body: body, orderId: orderId);
  }

  /// Shows a local notification via `flutter_local_notifications`.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? orderId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      FCMService.orderUpdatesChannelId,
      FCMService.orderUpdatesChannelName,
      channelDescription: FCMService.orderUpdatesChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      _notificationId++,
      title,
      body,
      notificationDetails,
      payload: orderId,
    );
  }

  /// Shows an in-app SnackBar with the notification content and a "View"
  /// action that navigates to the OrderTrackingScreen.
  void _showInAppSnackBar({
    required String title,
    required String body,
    String? orderId,
  }) {
    final messengerState = rootScaffoldMessengerKey.currentState;
    if (messengerState == null) return;

    messengerState.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: orderId != null && orderId.isNotEmpty
            ? SnackBarAction(
                label: 'View',
                onPressed: () {
                  final path = AppRoutes.orderTracking
                      .replaceFirst(':orderId', orderId);
                  _router.push(path);
                },
              )
            : null,
      ),
    );
  }

  /// Extracts the `orderId` from the notification data and navigates to
  /// the [OrderTrackingScreen].
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final orderId = data['orderId'] as String?;

    if (orderId == null || orderId.isEmpty) return;

    // Build the path from the route constant, replacing the parameter.
    final path = AppRoutes.orderTracking.replaceFirst(':orderId', orderId);
    _router.push(path);
  }
}

/// Riverpod provider for [NotificationHandler].
///
/// Requires [appRouterProvider] to be available for navigation.
@Riverpod(keepAlive: true)
NotificationHandler notificationHandler(Ref ref) {
  final router = ref.read(appRouterProvider);
  return NotificationHandler(
    messaging: FirebaseMessaging.instance,
    router: router,
    localNotifications: FlutterLocalNotificationsPlugin(),
  );
}
