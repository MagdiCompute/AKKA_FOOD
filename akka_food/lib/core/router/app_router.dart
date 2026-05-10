import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/notifiers/auth_notifier.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

/// Top-level route paths used throughout the app.
abstract final class AppRoutes {
  static const home = '/home';
  static const adminPrefix = '/admin';
}

// ---------------------------------------------------------------------------
// Pure redirect logic (testable without a widget tree)
// ---------------------------------------------------------------------------

/// Evaluates the admin route guard for [location] given the [currentUser].
///
/// Returns the redirect target path when access should be denied, or `null`
/// when the navigation is allowed to proceed.
///
/// Rules:
/// - Any route whose path starts with `/admin` requires `role == 'admin'`.
/// - Unauthenticated users (`currentUser == null`) are also redirected.
String? evaluateAdminGuard({
  required String location,
  required AppUser? currentUser,
}) {
  if (location.startsWith(AppRoutes.adminPrefix) &&
      !(currentUser?.isAdmin ?? false)) {
    return AppRoutes.home;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Placeholder screens (replace with real screens as they are implemented)
// ---------------------------------------------------------------------------

/// Home screen placeholder.
///
/// Displays an "Admin Dashboard" entry point in the navigation when the
/// currently signed-in user has the `admin` role (Requirement 1.1).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      body: Center(child: Text('Home')),
      // The admin entry point is only shown to users with the admin role.
      bottomNavigationBar: isAdmin
          ? BottomNavigationBar(
              currentIndex: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: 'Admin',
                ),
              ],
              onTap: (index) {
                if (index == 1) {
                  context.go(AppRoutes.adminPrefix);
                }
              },
            )
          : null,
    );
  }
}

class _AdminHomeScreen extends StatelessWidget {
  const _AdminHomeScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Admin Home')),
    );
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

/// Provides the application [GoRouter] instance.
///
/// The router is created once and kept alive for the lifetime of the app.
/// It reads [currentUserProvider] inside the `redirect` callback to enforce
/// the admin route guard (Requirement 1.2).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPrefix,
        builder: (context, state) => const _AdminHomeScreen(),
        routes: [
          // Admin sub-routes will be added here as the dashboard is built out.
          // e.g. GoRoute(path: 'orders', builder: ...),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final user = ref.read(currentUserProvider);
      return evaluateAdminGuard(
        location: state.matchedLocation,
        currentUser: user,
      );
    },
  );
});
