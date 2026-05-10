import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin_dashboard/presentation/screens/admin_category_list_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_category_form_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_analytics_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_home_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_meal_form_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_meal_list_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_order_detail_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_order_list_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_user_detail_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_user_list_screen.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/notifiers/auth_notifier.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

/// Top-level route paths used throughout the app.
abstract final class AppRoutes {
  static const home = '/home';

  // Admin root
  static const adminPrefix = '/admin';

  // Orders
  static const adminOrders = '/admin/orders';
  static const adminOrderDetail = '/admin/orders/:orderId';

  // Meals
  static const adminMeals = '/admin/meals';
  static const adminMealNew = '/admin/meals/new';
  static const adminMealEdit = '/admin/meals/:mealId/edit';

  // Categories
  static const adminCategories = '/admin/categories';
  static const adminCategoryNew = '/admin/categories/new';
  static const adminCategoryEdit = '/admin/categories/:categoryId/edit';

  // Analytics
  static const adminAnalytics = '/admin/analytics';

  // Users
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/:userId';
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
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          // ── Orders ──────────────────────────────────────────────────────
          GoRoute(
            path: 'orders',
            builder: (context, state) => const AdminOrderListScreen(),
            routes: [
              GoRoute(
                path: ':orderId',
                builder: (context, state) => AdminOrderDetailScreen(
                  orderId: state.pathParameters['orderId']!,
                ),
              ),
            ],
          ),

          // ── Meals ────────────────────────────────────────────────────────
          GoRoute(
            path: 'meals',
            builder: (context, state) => const AdminMealListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const AdminMealFormScreen(),
              ),
              GoRoute(
                path: ':mealId/edit',
                builder: (context, state) => AdminMealFormScreen(
                  mealId: state.pathParameters['mealId'],
                ),
              ),
            ],
          ),

          // ── Categories ───────────────────────────────────────────────────
          GoRoute(
            path: 'categories',
            builder: (context, state) => const AdminCategoryListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const AdminCategoryFormScreen(),
              ),
              GoRoute(
                path: ':categoryId/edit',
                builder: (context, state) => AdminCategoryFormScreen(
                  categoryId: state.pathParameters['categoryId'],
                ),
              ),
            ],
          ),

          // ── Analytics ────────────────────────────────────────────────────
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),

          // ── Users ────────────────────────────────────────────────────────
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUserListScreen(),
            routes: [
              GoRoute(
                path: ':userId',
                builder: (context, state) => AdminUserDetailScreen(
                  userId: state.pathParameters['userId']!,
                ),
              ),
            ],
          ),
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
