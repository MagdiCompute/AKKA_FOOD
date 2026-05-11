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
import '../../features/auth/presentation/notifiers/auth_state.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/user_profile/presentation/screens/address_form_screen.dart';
import '../../features/user_profile/presentation/screens/address_list_screen.dart';
import '../../features/user_profile/presentation/screens/coin_history_screen.dart';
import '../../features/user_profile/presentation/screens/edit_profile_screen.dart';
import '../../features/user_profile/presentation/screens/notification_prefs_screen.dart';
import '../../features/user_profile/presentation/screens/order_detail_screen.dart';
import '../../features/user_profile/presentation/screens/order_history_screen.dart';
import '../../features/user_profile/presentation/screens/profile_screen.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

/// Top-level route paths used throughout the app.
abstract final class AppRoutes {
  static const home = '/home';

  // Auth
  static const login = '/login';
  static const signup = '/signup';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/change-password';

  // User Profile
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const addresses = '/profile/addresses';
  static const addressNew = '/profile/addresses/new';
  static const addressEdit = '/profile/addresses/:addressId/edit';
  static const orderHistory = '/profile/orders';
  static const orderDetail = '/profile/orders/:orderId';
  static const coinHistory = '/profile/coins';
  static const notificationPrefs = '/profile/notifications';

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

/// Auth route guard — pure function, testable without a widget tree.
///
/// Returns the redirect path or `null` (allow navigation).
///
/// Rules:
/// - While [AuthStatus.initial] (session restore in progress), allow all
///   navigation so the splash/loading state can render.
/// - 8.3 — Authenticated users are redirected away from auth screens to
///   [AppRoutes.home].
/// - 8.2 — Unauthenticated users are redirected to [AppRoutes.login] when
///   they attempt to access any protected route.
String? evaluateAuthGuard({
  required String location,
  required AuthStatus authStatus,
}) {
  // Auth screens — no authentication required.
  const authScreens = [
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.otp,
    AppRoutes.forgotPassword,
  ];

  final isAuthScreen = authScreens.any((path) => location.startsWith(path));
  final isAuthenticated = authStatus == AuthStatus.authenticated;
  final isInitial = authStatus == AuthStatus.initial;

  // While session is being restored (initial), don't redirect — let the
  // splash/loading state show.
  if (isInitial) return null;

  // 8.3 — Authenticated users skip auth screens → go to home.
  if (isAuthenticated && isAuthScreen) return AppRoutes.home;

  // 8.2 — Unauthenticated users can't access protected routes.
  if (!isAuthenticated && !isAuthScreen) return AppRoutes.login;

  return null;
}

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
// RouterNotifier — bridges Riverpod auth state to GoRouter's refreshListenable
// ---------------------------------------------------------------------------

/// A [ChangeNotifier] that listens to [authNotifierProvider] and notifies
/// GoRouter whenever the auth state changes, triggering a re-evaluation of
/// the `redirect` callback.
///
/// Implements [Listenable] so it can be passed directly to
/// [GoRouter.refreshListenable].
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    // Listen to auth state changes and notify GoRouter to re-run redirect.
    ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
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
/// It reads [authNotifierProvider] and [currentUserProvider] inside the
/// `redirect` callback to enforce both the auth guard (Requirements 8.2, 8.3)
/// and the admin route guard (Requirement 1.2).
///
/// [RouterNotifier] is used as [GoRouter.refreshListenable] so the router
/// re-evaluates the redirect whenever the auth state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: routerNotifier,
    routes: [
      // ── Auth routes ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // ── Home ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),

      // ── User Profile ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (context, state) => const AddressListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressNew,
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressEdit,
        builder: (context, state) => AddressFormScreen(
          addressId: state.pathParameters['addressId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.orderHistory,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.coinHistory,
        builder: (context, state) => const CoinHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationPrefs,
        builder: (context, state) => const NotificationPrefsScreen(),
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
      final authState = ref.read(authNotifierProvider);
      final user = ref.read(currentUserProvider);

      // Auth guard first (8.2 & 8.3).
      final authRedirect = evaluateAuthGuard(
        location: state.matchedLocation,
        authStatus: authState.status,
      );
      if (authRedirect != null) return authRedirect;

      // Admin guard second.
      return evaluateAdminGuard(
        location: state.matchedLocation,
        currentUser: user,
      );
    },
  );
});
