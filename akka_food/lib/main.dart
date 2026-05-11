import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'features/user_profile/data/datasources/hive_profile_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive and open all user-profile cache boxes.
  await Hive.initFlutter();
  await Hive.openBox<String>(kProfileCacheBox);
  await Hive.openBox<String>(kAddressCacheBox);
  await Hive.openBox<String>(kOrderHistoryCacheBox);
  await Hive.openBox<String>(kCoinHistoryCacheBox);

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
