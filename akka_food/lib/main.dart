import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

void main() {
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
