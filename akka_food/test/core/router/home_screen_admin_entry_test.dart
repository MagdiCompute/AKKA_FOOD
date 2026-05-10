// Widget tests for the admin navigation entry point on HomeScreen.
//
// Requirement 1.1: WHEN a User with the `admin` role signs in, THE Flutter app
// SHALL display an Admin Dashboard entry point in the navigation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
        final container = ProviderContainer(
          overrides: [
            currentUserProvider
                .overrideWith((ref) => _makeUser(role: 'admin')),
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        // The bottom nav bar should be present with an "Admin" label.
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
        expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
      },
    );

    testWidgets(
      'non-admin user does NOT see the Admin bottom nav item',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider
                .overrideWith((ref) => _makeUser(role: 'user')),
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        // No bottom nav bar and no "Admin" label for regular users.
        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(find.text('Admin'), findsNothing);
        expect(find.byIcon(Icons.admin_panel_settings), findsNothing);
      },
    );

    testWidgets(
      'unauthenticated user does NOT see the Admin bottom nav item',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(find.text('Admin'), findsNothing);
      },
    );

    testWidgets(
      'tapping Admin nav item navigates to /admin for admin user',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider
                .overrideWith((ref) => _makeUser(role: 'admin')),
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
        final container = ProviderContainer(
          overrides: [
            currentUserProvider
                .overrideWith((ref) => _makeUser(role: 'user')),
          ],
        );
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        // Regular user: no admin entry point.
        expect(find.byType(BottomNavigationBar), findsNothing);

        // Promote to admin.
        container.read(currentUserProvider.notifier).state =
            _makeUser(role: 'admin');
        await tester.pumpAndSettle();

        // Admin entry point should now be visible.
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
      },
    );
  });
}
