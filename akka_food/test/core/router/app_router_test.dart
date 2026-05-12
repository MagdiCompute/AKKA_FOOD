import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/core/router/app_router.dart';
import 'package:akka_food/features/admin_dashboard/domain/entities/admin_order_view.dart';
import 'package:akka_food/features/admin_dashboard/domain/entities/admin_user_view.dart';
import 'package:akka_food/features/admin_dashboard/domain/entities/category.dart'
    as admin_cat;
import 'package:akka_food/features/admin_dashboard/domain/entities/meal.dart'
    as admin_meal;
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_analytics_repository.dart';
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_category_repository.dart';
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_meal_repository.dart';
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_order_repository.dart';
import 'package:akka_food/features/admin_dashboard/domain/repositories/i_admin_user_repository.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_analytics_notifier.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_category_notifier.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_meal_notifier.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_order_notifier.dart';
import 'package:akka_food/features/admin_dashboard/presentation/notifiers/admin_user_notifier.dart';
import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_state.dart';
import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart'
    as cart_do;
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppUser _makeUser({String role = 'user'}) => AppUser(
      uid: 'uid_test',
      email: 'test@example.com',
      phoneNumber: null,
      displayName: 'Test User',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
      role: role,
    );

/// Override for [cartNotifierProvider] that avoids Hive initialization.
final _cartOverride = cartNotifierProvider.overrideWith(() => _FakeCartNotifier());

class _FakeCartNotifier extends CartNotifier {
  @override
  Cart build() => Cart(items: const [], deliveryOption: cart_do.DeliveryOption.delivery);
}

/// Fake [IAdminUserRepository] that avoids Firebase dependency.
class _FakeAdminUserRepository implements IAdminUserRepository {
  @override
  Stream<List<AdminUserView>> watchAllUsers() => Stream.value([]);

  @override
  Future<AdminUserView?> getUserById(String uid) async => null;

  @override
  Future<List<AdminOrderView>> getUserOrders(String uid) async => [];

  @override
  Future<void> deactivateUser(String uid) async {}

  @override
  Future<void> reactivateUser(String uid) async {}
}

class _FakeAdminOrderRepository implements IAdminOrderRepository {
  @override
  Stream<List<AdminOrderView>> watchActiveOrders() => Stream.value([]);

  @override
  Future<AdminOrderView?> getOrderById(String orderId) async => null;

  @override
  Future<void> updateOrderStatus(String orderId, DeliveryStatus status,
      {int? etaMinutes}) async {}
}

class _FakeAdminMealRepository implements IAdminMealRepository {
  @override
  Stream<List<admin_meal.Meal>> watchAllMeals() => Stream.value([]);

  @override
  Future<List<admin_meal.Meal>> getAllMeals() async => [];

  @override
  Future<void> toggleAvailability(String mealId,
      {required bool isAvailable}) async {}

  @override
  Future<String> createMeal(Map<String, dynamic> data) async => 'fake-id';

  @override
  Future<void> updateMeal(String mealId, Map<String, dynamic> data) async {}

  @override
  Future<void> deleteMeal(String mealId) async {}
}

class _FakeAdminAnalyticsRepository implements IAdminAnalyticsRepository {
  @override
  Stream<Map<String, dynamic>> watchSummary() => Stream.value({});
}

class _FakeAdminCategoryRepository implements IAdminCategoryRepository {
  @override
  Stream<List<admin_cat.Category>> watchAllCategories() => Stream.value([]);

  @override
  Future<List<admin_cat.Category>> getAllCategories() async => [];

  @override
  Future<String> createCategory(Map<String, dynamic> data) async => 'fake-id';

  @override
  Future<void> updateCategory(
      String categoryId, Map<String, dynamic> data) async {}

  @override
  Future<void> deactivateCategory(String categoryId) async {}

  @override
  Future<void> activateCategory(String categoryId) async {}
}

/// All admin repository overrides needed for widget tests.
final _adminOverrides = <Override>[
  adminUserRepositoryProvider
      .overrideWith((ref) => _FakeAdminUserRepository()),
  adminOrderRepositoryProvider
      .overrideWith((ref) => _FakeAdminOrderRepository()),
  adminMealRepositoryProvider
      .overrideWith((ref) => _FakeAdminMealRepository()),
  adminAnalyticsRepositoryProvider
      .overrideWith((ref) => _FakeAdminAnalyticsRepository()),
  adminCategoryRepositoryProvider
      .overrideWith((ref) => _FakeAdminCategoryRepository()),
];

// ---------------------------------------------------------------------------
// Unit tests — pure redirect logic (no widget tree required)
// ---------------------------------------------------------------------------

void main() {
  group('evaluateAuthGuard — pure redirect logic', () {
    // ── AuthStatus.initial (session restore in progress) ───────────────────

    test('returns null for initial status on /login (no redirect during restore)',
        () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.login,
          authStatus: AuthStatus.initial,
        ),
        isNull,
      );
    });

    test('returns null for initial status on /home (no redirect during restore)',
        () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.home,
          authStatus: AuthStatus.initial,
        ),
        isNull,
      );
    });

    // ── 8.2 — Unauthenticated users redirected to /login ───────────────────

    test('returns /login for unauthenticated user on /home', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.home,
          authStatus: AuthStatus.unauthenticated,
        ),
        equals(AppRoutes.login),
      );
    });

    test('returns /login for unauthenticated user on /change-password', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.changePassword,
          authStatus: AuthStatus.unauthenticated,
        ),
        equals(AppRoutes.login),
      );
    });

    test('returns /login for unauthenticated user on /admin', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.adminPrefix,
          authStatus: AuthStatus.unauthenticated,
        ),
        equals(AppRoutes.login),
      );
    });

    test('returns /login for unauthenticated user on /admin/orders', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.adminOrders,
          authStatus: AuthStatus.unauthenticated,
        ),
        equals(AppRoutes.login),
      );
    });

    test('returns null for unauthenticated user on /login (allow access)', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.login,
          authStatus: AuthStatus.unauthenticated,
        ),
        isNull,
      );
    });

    test('returns null for unauthenticated user on /signup (allow access)', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.signup,
          authStatus: AuthStatus.unauthenticated,
        ),
        isNull,
      );
    });

    test('returns null for unauthenticated user on /otp (allow access)', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.otp,
          authStatus: AuthStatus.unauthenticated,
        ),
        isNull,
      );
    });

    test(
        'returns null for unauthenticated user on /forgot-password (allow access)',
        () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.forgotPassword,
          authStatus: AuthStatus.unauthenticated,
        ),
        isNull,
      );
    });

    // ── 8.3 — Authenticated users redirected away from auth screens ─────────

    test('returns /home for authenticated user on /login', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.login,
          authStatus: AuthStatus.authenticated,
        ),
        equals(AppRoutes.home),
      );
    });

    test('returns /home for authenticated user on /signup', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.signup,
          authStatus: AuthStatus.authenticated,
        ),
        equals(AppRoutes.home),
      );
    });

    test('returns /home for authenticated user on /otp', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.otp,
          authStatus: AuthStatus.authenticated,
        ),
        equals(AppRoutes.home),
      );
    });

    test('returns /home for authenticated user on /forgot-password', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.forgotPassword,
          authStatus: AuthStatus.authenticated,
        ),
        equals(AppRoutes.home),
      );
    });

    test('returns null for authenticated user on /home (allow access)', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.home,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    test(
        'returns null for authenticated user on /change-password (allow access)',
        () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.changePassword,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    test('returns null for authenticated user on /admin (allow access)', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.adminPrefix,
          authStatus: AuthStatus.authenticated,
        ),
        isNull,
      );
    });

    // ── Error / loading states treated as unauthenticated ──────────────────

    test('returns /login for error status on /home', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.home,
          authStatus: AuthStatus.error,
        ),
        equals(AppRoutes.login),
      );
    });

    test('returns /login for loading status on /home', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.home,
          authStatus: AuthStatus.loading,
        ),
        equals(AppRoutes.login),
      );
    });

    test('returns null for loading status on /login (allow access)', () {
      expect(
        evaluateAuthGuard(
          location: AppRoutes.login,
          authStatus: AuthStatus.loading,
        ),
        isNull,
      );
    });
  });

  group('evaluateAdminGuard — pure redirect logic', () {
    // ── Unauthenticated user ────────────────────────────────────────────────

    test('returns /home for unauthenticated user on /admin', () {
      expect(
        evaluateAdminGuard(location: '/admin', currentUser: null),
        equals('/home'),
      );
    });

    test('returns /home for unauthenticated user on /admin/orders', () {
      expect(
        evaluateAdminGuard(location: '/admin/orders', currentUser: null),
        equals('/home'),
      );
    });

    test('returns null for unauthenticated user on /home', () {
      expect(
        evaluateAdminGuard(location: '/home', currentUser: null),
        isNull,
      );
    });

    // ── Regular (non-admin) user ────────────────────────────────────────────

    test('returns /home for non-admin user on /admin', () {
      expect(
        evaluateAdminGuard(
          location: '/admin',
          currentUser: _makeUser(role: 'user'),
        ),
        equals('/home'),
      );
    });

    test('returns /home for non-admin user on /admin/meals', () {
      expect(
        evaluateAdminGuard(
          location: '/admin/meals',
          currentUser: _makeUser(role: 'user'),
        ),
        equals('/home'),
      );
    });

    test('returns null for non-admin user on /home', () {
      expect(
        evaluateAdminGuard(
          location: '/home',
          currentUser: _makeUser(role: 'user'),
        ),
        isNull,
      );
    });

    test('returns null for non-admin user on /profile', () {
      expect(
        evaluateAdminGuard(
          location: '/profile',
          currentUser: _makeUser(role: 'user'),
        ),
        isNull,
      );
    });

    // ── Admin user ──────────────────────────────────────────────────────────

    test('returns null for admin user on /admin', () {
      expect(
        evaluateAdminGuard(
          location: '/admin',
          currentUser: _makeUser(role: 'admin'),
        ),
        isNull,
      );
    });

    test('returns null for admin user on /admin/orders', () {
      expect(
        evaluateAdminGuard(
          location: '/admin/orders',
          currentUser: _makeUser(role: 'admin'),
        ),
        isNull,
      );
    });

    test('returns null for admin user on /admin/meals/new', () {
      expect(
        evaluateAdminGuard(
          location: '/admin/meals/new',
          currentUser: _makeUser(role: 'admin'),
        ),
        isNull,
      );
    });

    test('returns null for admin user on /home', () {
      expect(
        evaluateAdminGuard(
          location: '/home',
          currentUser: _makeUser(role: 'admin'),
        ),
        isNull,
      );
    });

    // ── Edge cases ──────────────────────────────────────────────────────────

    test('does not treat /administrator as an admin route', () {
      // /administrator starts with /admin — this is intentional per the spec.
      // The guard protects anything under /admin*.
      expect(
        evaluateAdminGuard(
          location: '/administrator',
          currentUser: _makeUser(role: 'user'),
        ),
        equals('/home'),
        reason: '/administrator starts with /admin so it is guarded',
      );
    });

    test('unknown role is treated as non-admin', () {
      expect(
        evaluateAdminGuard(
          location: '/admin',
          currentUser: _makeUser(role: 'moderator'),
        ),
        equals('/home'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Widget tests — GoRouter integration
  // ---------------------------------------------------------------------------

  group('Admin route guard — GoRouter widget integration', () {
    testWidgets(
        'non-admin user navigating to /admin sees home screen content',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _makeUser(role: 'user')),
          _cartOverride,
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      router.go('/admin');
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
      // AdminHomeScreen tab icons should not be visible.
      expect(find.byIcon(Icons.receipt_long), findsNothing);
    });

    testWidgets(
        'unauthenticated user navigating to /admin sees home screen content',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          _cartOverride,
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      router.go('/admin');
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
      // AdminHomeScreen tab icons should not be visible.
      expect(find.byIcon(Icons.receipt_long), findsNothing);
    });

    testWidgets('admin user navigating to /admin sees admin screen content',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _makeUser(role: 'admin')),
          _cartOverride,
          ..._adminOverrides,
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      router.go('/admin');
      await tester.pumpAndSettle();

      // AdminHomeScreen renders a BottomNavigationBar with 4 admin tabs.
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets(
        'user promoted to admin can access /admin after provider update',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _makeUser(role: 'user')),
          _cartOverride,
          ..._adminOverrides,
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Regular user is redirected away from /admin.
      router.go('/admin');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsWidgets);

      // Promote to admin.
      container.read(currentUserProvider.notifier).state =
          _makeUser(role: 'admin');

      // Now navigating to /admin should succeed.
      router.go('/admin');
      await tester.pumpAndSettle();
      // AdminHomeScreen bottom nav is now visible.
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    });
  });
}
