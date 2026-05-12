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
import '../../features/delivery_system/presentation/screens/order_tracking_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/meal_catalog/presentation/screens/catalog_screen.dart';
import '../../features/meal_catalog/presentation/screens/meal_detail_screen.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/notifiers/auth_notifier.dart';
import '../../features/auth/presentation/notifiers/auth_state.dart';
import '../../features/cart/presentation/notifiers/cart_notifier.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/payment_processing/presentation/screens/checkout_screen.dart';
import '../../features/payment_processing/presentation/screens/order_confirmation_screen.dart';
import '../../features/payment_processing/presentation/screens/payment_failure_screen.dart';
import '../../features/payment_processing/presentation/screens/payment_processing_screen.dart';
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

  // Order Tracking
  static const orderTracking = '/orders/:orderId/tracking';

  // Catalog
  static const catalog = '/catalog';
  static const mealDetail = '/meals/:mealId';

  // Leaderboard
  static const leaderboard = '/leaderboard';

  // Cart & Payment
  static const cart = '/cart';
  static const payment = '/payment';
  static const paymentProcessing = '/payment/processing';
  static const paymentConfirmation = '/payment/confirmation';
  static const paymentFailure = '/payment/failure';

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

/// Home screen shell.
///
/// Displays a Material 3 [NavigationBar] with:
/// - Home tab (index 0) → [AppRoutes.home]
/// - Cart tab (index 1) → [AppRoutes.cart] with a badge showing the item
///   count (Requirement 2.4)
/// - Profile tab (index 2) → [AppRoutes.profile]
/// - Admin tab (index 3, admin users only) → [AppRoutes.adminPrefix]
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.isAdmin ?? false;
    final cart = ref.watch(cartNotifierProvider);
    final itemCount = cart.itemCount;

    // Build navigation destinations dynamically based on user role.
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: itemCount > 0,
          label: Text(itemCount > 99 ? '99+' : '$itemCount'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: itemCount > 0,
          label: Text(itemCount > 99 ? '99+' : '$itemCount'),
          child: const Icon(Icons.shopping_cart),
        ),
        label: 'Cart',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Text(
            'Welcome to AKKA Food',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _HomeNavCard(
            icon: Icons.restaurant_menu,
            title: 'Browse Meals',
            subtitle: 'Explore our meal catalog',
            onTap: () => context.push(AppRoutes.catalog),
          ),
          _HomeNavCard(
            icon: Icons.leaderboard,
            title: 'Leaderboard',
            subtitle: 'See top users',
            onTap: () => context.push('/leaderboard'),
          ),
          _HomeNavCard(
            icon: Icons.shopping_cart,
            title: 'My Cart',
            subtitle: 'View your cart',
            onTap: () => context.go(AppRoutes.cart),
          ),
          _HomeNavCard(
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'View and edit your profile',
            onTap: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: destinations,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.cart);
            case 2:
              context.go(AppRoutes.profile);
            case 3:
              if (isAdmin) context.go(AppRoutes.adminPrefix);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HomeNavCard — navigation card for the home screen
// ---------------------------------------------------------------------------

class _HomeNavCard extends StatelessWidget {
  const _HomeNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
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

      // ── Cart ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),

      // ── Leaderboard ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),

      // ── Catalog ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.catalog,
        builder: (context, state) => const CatalogScreen(),
      ),

      // ── Meal Detail ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.mealDetail,
        builder: (context, state) => MealDetailScreen(
          mealId: state.pathParameters['mealId']!,
        ),
      ),

      // ── Payment ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentProcessing,
        builder: (context, state) => const PaymentProcessingScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentConfirmation,
        builder: (context, state) => const OrderConfirmationScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentFailure,
        builder: (context, state) => const PaymentFailureScreen(),
      ),

      // ── Order Tracking ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.orderTracking,
        builder: (context, state) => OrderTrackingScreen(
          orderId: state.pathParameters['orderId']!,
        ),
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
