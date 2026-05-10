import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/core/router/app_router.dart';
import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';

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
// Unit tests — pure redirect logic (no widget tree required)
// ---------------------------------------------------------------------------

void main() {
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

      expect(find.text('Home'), findsOneWidget);
      // AdminHomeScreen tab icons should not be visible.
      expect(find.byIcon(Icons.receipt_long), findsNothing);
    });

    testWidgets(
        'unauthenticated user navigating to /admin sees home screen content',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
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

      expect(find.text('Home'), findsOneWidget);
      // AdminHomeScreen tab icons should not be visible.
      expect(find.byIcon(Icons.receipt_long), findsNothing);
    });

    testWidgets('admin user navigating to /admin sees admin screen content',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _makeUser(role: 'admin')),
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
      expect(find.text('Home'), findsOneWidget);

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
