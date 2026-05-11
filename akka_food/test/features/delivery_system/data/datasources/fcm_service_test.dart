import 'dart:async';

import 'package:akka_food/features/delivery_system/data/datasources/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FCMService', () {
    late FakeFirebaseMessaging fakeMessaging;
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseAuth fakeAuth;
    late FakeLocalNotifications fakeLocalNotifications;
    late FCMService service;

    setUp(() {
      fakeMessaging = FakeFirebaseMessaging();
      fakeFirestore = FakeFirebaseFirestore();
      fakeAuth = FakeFirebaseAuth(uid: 'test-user-123');
      fakeLocalNotifications = FakeLocalNotifications();

      service = FCMService(
        messaging: fakeMessaging,
        firestore: fakeFirestore,
        auth: fakeAuth,
        localNotifications: fakeLocalNotifications,
      );
    });

    group('requestPermission', () {
      test('requests notification permissions from FirebaseMessaging', () async {
        final settings = await service.requestPermission();
        expect(settings, isNotNull);
        expect(fakeMessaging.permissionRequested, isTrue);
      });
    });

    group('initialize', () {
      test('gets FCM token and stores it in Firestore', () async {
        fakeMessaging.tokenToReturn = 'fake-fcm-token-abc';

        await service.initialize();

        final doc = await fakeFirestore
            .collection('users')
            .doc('test-user-123')
            .get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['fcmToken'], 'fake-fcm-token-abc');
      });

      test('does not write to Firestore when token is null', () async {
        fakeMessaging.tokenToReturn = null;

        await service.initialize();

        final doc = await fakeFirestore
            .collection('users')
            .doc('test-user-123')
            .get();
        expect(doc.exists, isFalse);
      });

      test('does not write to Firestore when user is not authenticated', () async {
        fakeMessaging.tokenToReturn = 'some-token';
        fakeAuth = FakeFirebaseAuth(uid: null);
        service = FCMService(
          messaging: fakeMessaging,
          firestore: fakeFirestore,
          auth: fakeAuth,
          localNotifications: fakeLocalNotifications,
        );

        await service.initialize();

        final snapshot = await fakeFirestore.collection('users').get();
        expect(snapshot.docs, isEmpty);
      });
    });

    group('token refresh', () {
      test('updates Firestore when token refreshes', () async {
        fakeMessaging.tokenToReturn = 'initial-token';

        await service.initialize();

        // Simulate token refresh
        fakeMessaging.emitTokenRefresh('refreshed-token-xyz');

        // Allow the stream listener to process
        await Future<void>.delayed(Duration.zero);

        final doc = await fakeFirestore
            .collection('users')
            .doc('test-user-123')
            .get();
        expect(doc.data()?['fcmToken'], 'refreshed-token-xyz');
      });
    });

    group('constants', () {
      test('has correct channel ID', () {
        expect(FCMService.orderUpdatesChannelId, 'order_updates');
      });

      test('has correct channel name', () {
        expect(FCMService.orderUpdatesChannelName, 'Order Updates');
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  bool permissionRequested = false;
  String? tokenToReturn = 'fake-token';
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool providesAppNotificationSettings = false,
    bool sound = true,
  }) async {
    permissionRequested = true;
    return const NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      authorizationStatus: AuthorizationStatus.authorized,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      sound: AppleNotificationSetting.enabled,
      timeSensitive: AppleNotificationSetting.disabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
  }

  @override
  Future<String?> getToken({String? vapidKey}) async => tokenToReturn;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  void emitTokenRefresh(String token) {
    _tokenRefreshController.add(token);
  }
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  FakeFirebaseAuth({required this.uid});

  final String? uid;

  @override
  User? get currentUser => uid != null ? FakeUser(uid: uid!) : null;
}

class FakeUser extends Fake implements User {
  FakeUser({required this.uid});

  @override
  final String uid;
}

class FakeLocalNotifications extends Fake
    implements FlutterLocalNotificationsPlugin {
  @override
  T? resolvePlatformSpecificImplementation<
      T extends FlutterLocalNotificationsPlatform>() {
    // Return null since we're not on Android in tests
    return null;
  }
}
