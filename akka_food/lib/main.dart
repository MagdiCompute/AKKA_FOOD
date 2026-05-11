import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'features/cart/data/datasources/hive_cart_datasource.dart';
import 'features/cart/data/datasources/remote_config_service.dart';
import 'features/delivery_system/data/datasources/fcm_service.dart';
import 'features/delivery_system/data/datasources/notification_handler.dart'
    show rootScaffoldMessengerKey, notificationHandlerProvider;
import 'features/user_profile/data/datasources/hive_profile_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (uses platform-native config: google-services.json / GoogleService-Info.plist).
  await Firebase.initializeApp();

  // Initialise Hive and open all user-profile cache boxes.
  await Hive.initFlutter();
  await Hive.openBox<String>(kProfileCacheBox);
  await Hive.openBox<String>(kAddressCacheBox);
  await Hive.openBox<String>(kOrderHistoryCacheBox);
  await Hive.openBox<String>(kCoinHistoryCacheBox);

  // Open cart box for cart persistence.
  await Hive.openBox<String>(kCartBox);

  // Fetch and cache Remote Config values (delivery fee, etc.).
  // The SDK caches locally with a 1-hour minimum fetch interval.
  final remoteConfigService = RemoteConfigService(FirebaseRemoteConfig.instance);
  await remoteConfigService.initialize();
  await remoteConfigService.fetchAndActivate();

  // Initialize Flutter Local Notifications plugin for Android channel setup.
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initSettings);

  // Initialize Firebase Cloud Messaging for push notifications.
  final fcmService = FCMService(
    messaging: FirebaseMessaging.instance,
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    localNotifications: localNotifications,
  );
  await fcmService.initialize();

  runApp(
    // ProviderScope is required for Riverpod to work.
    const ProviderScope(child: AkkaFoodApp()),
  );
}

/// Root widget of the AKKA Food application.
class AkkaFoodApp extends ConsumerStatefulWidget {
  const AkkaFoodApp({super.key});

  @override
  ConsumerState<AkkaFoodApp> createState() => _AkkaFoodAppState();
}

class _AkkaFoodAppState extends ConsumerState<AkkaFoodApp> {
  bool _notificationHandlerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Schedule notification handler initialization after the first frame,
    // ensuring the router is fully available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotificationHandler();
    });
  }

  Future<void> _initNotificationHandler() async {
    if (_notificationHandlerInitialized) return;
    _notificationHandlerInitialized = true;

    final handler = ref.read(notificationHandlerProvider);
    await handler.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AKKA Food',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      routerConfig: router,
    );
  }
}
