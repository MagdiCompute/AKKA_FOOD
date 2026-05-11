import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_service.g.dart';

/// Service responsible for Firebase Cloud Messaging setup:
/// - Requesting notification permissions
/// - Retrieving and storing the FCM token in Firestore
/// - Listening for token refresh
/// - Creating Android notification channels
class FCMService {
  FCMService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FlutterLocalNotificationsPlugin localNotifications,
  })  : _messaging = messaging,
        _firestore = firestore,
        _auth = auth,
        _localNotifications = localNotifications;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterLocalNotificationsPlugin _localNotifications;

  /// Android notification channel for order status updates.
  static const String orderUpdatesChannelId = 'order_updates';
  static const String orderUpdatesChannelName = 'Order Updates';
  static const String orderUpdatesChannelDescription =
      'Notifications for delivery order status changes';

  /// Initializes the FCM service:
  /// 1. Creates Android notification channel
  /// 2. Requests notification permissions
  /// 3. Gets and stores the FCM token
  /// 4. Listens for token refresh
  Future<void> initialize() async {
    await _createAndroidNotificationChannel();
    await requestPermission();
    await _getAndStoreToken();
    _listenForTokenRefresh();
  }

  /// Requests notification permissions from the user.
  /// Returns the [NotificationSettings] with the authorization status.
  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings;
  }

  /// Gets the current FCM token and saves it to Firestore.
  Future<void> _getAndStoreToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  /// Listens for FCM token refresh events and updates Firestore.
  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  /// Saves the FCM token to Firestore at `users/{uid}.fcmToken`.
  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// Creates the Android notification channel for order updates.
  Future<void> _createAndroidNotificationChannel() async {
    if (!Platform.isAndroid) return;

    const androidChannel = AndroidNotificationChannel(
      orderUpdatesChannelId,
      orderUpdatesChannelName,
      description: orderUpdatesChannelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
}

/// Riverpod provider for [FCMService].
@Riverpod(keepAlive: true)
FCMService fcmService(Ref ref) {
  return FCMService(
    messaging: FirebaseMessaging.instance,
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    localNotifications: FlutterLocalNotificationsPlugin(),
  );
}
