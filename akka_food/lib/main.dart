import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'features/cart/data/datasources/hive_cart_datasource.dart';
import 'features/cart/data/datasources/remote_config_service.dart';
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

  runApp(
    // ProviderScope is required for Riverpod to work.
    const ProviderScope(child: AkkaFoodApp()),
  );
}

/// Root widget of the AKKA Food application.
class AkkaFoodApp extends ConsumerWidget {
  const AkkaFoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AKKA Food',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      routerConfig: router,
    );
  }
}
