// Widget tests for the admin navigation entry point on HomeScreen.
//
// Requirement 1.1: WHEN a User with the `admin` role signs in, THE Flutter app
// SHALL display an Admin Dashboard entry point in the navigation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

// ---------------------------------------------------------------------------
// Fakes for providers that depend on Firebase/Hive
// ---------------------------------------------------------------------------

class _FakeCartNotifier extends CartNotifier {
  @override
  Cart build() =>
      Cart(items: const [], deliveryOption: cart_do.DeliveryOption.delivery);
}

/// Fake [AuthNotifier] that returns an authenticated state without Firebase.
class _FakeAuthNotifier extends AuthNotifier {
  final AppUser? _user;
  _FakeAuthNotifier(this._user);

  @override
  AuthState build() => _user != null
      ? AuthState.authenticated(_user)
      : const AuthState.unauthenticated();
}

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

final _testOverrides = <Override>[
  cartNotifierProvider.overrideWith(() => _FakeCartNotifier()),
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

/// Pumps the full app with [GoRouter] so that navigation works correctly.
Future<void> _pumpApp(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeScreen — admin navigation entry point', () {
    testWidgets(
      'admin user sees the Admin bottom nav item',
      (tester) async {
        final user = _makeUser(role: 'admin');
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(user)),
            currentUserProvider.overrideWith((ref) => user),
            ..._testOverrides,
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        // The bottom nav bar should be present with an "Admin" label.
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
        expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'non-admin user does NOT see the Admin bottom nav item',
      (tester) async {
        final user = _makeUser(role: 'user');
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(user)),
            currentUserProvider.overrideWith((ref) => user),
            ..._testOverrides,
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        // Regular users see the bottom nav bar (Home + Cart) but NOT the Admin tab.
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Admin'), findsNothing);
        expect(find.byIcon(Icons.admin_panel_settings), findsNothing);
      },
    );

    testWidgets(
      'unauthenticated user does NOT see the Admin bottom nav item',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(null)),
            currentUserProvider.overrideWith((ref) => null),
            ..._testOverrides,
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        expect(find.text('Admin'), findsNothing);
        expect(find.byIcon(Icons.admin_panel_settings), findsNothing);
      },
    );

    testWidgets(
      'tapping Admin nav item navigates to /admin for admin user',
      (tester) async {
        final user = _makeUser(role: 'admin');
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(user)),
            currentUserProvider.overrideWith((ref) => user),
            ..._testOverrides,
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        // Tap the "Admin" bottom nav item.
        await tester.tap(find.text('Admin'));
        await tester.pumpAndSettle();

        // Should now be on AdminHomeScreen — identified by its 4 admin tab icons.
        expect(find.byIcon(Icons.receipt_long), findsOneWidget);
        expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
        expect(find.byIcon(Icons.bar_chart), findsOneWidget);
        expect(find.byIcon(Icons.people), findsOneWidget);
      },
    );

    testWidgets(
      'admin entry point appears when user is promoted to admin at runtime',
      (tester) async {
        final user = _makeUser(role: 'user');
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(() => _FakeAuthNotifier(user)),
            currentUserProvider.overrideWith((ref) => user),
            ..._testOverrides,
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        // Regular user: bottom nav is visible (Home + Cart) but no admin tab.
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Admin'), findsNothing);

        // Promote to admin.
        container.read(currentUserProvider.notifier).state =
            _makeUser(role: 'admin');
        await tester.pumpAndSettle();

        // Admin entry point should now be visible.
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
      },
    );
  });
}
