// integration_test/user_profile_view_edit_test.dart
//
// Task 9.1 — View and edit profile integration tests
//
// Tests that the ProfileScreen displays user data and that EditProfileScreen
// validates and saves changes. Uses FakeProfileRepository and a fake
// currentUserProvider injected via ProviderScope overrides. No real Firebase
// connection is made.
//
// The full GoRouter is used so that navigation between ProfileScreen and
// EditProfileScreen works correctly. The router starts at /login but the
// auth guard immediately redirects authenticated users to /home; from there
// the test navigates to /profile.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/core/router/app_router.dart';
import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/user_profile/domain/entities/notification_preference.dart';
import 'package:akka_food/features/user_profile/domain/entities/user_profile.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_profile_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/profile_notifier.dart';
import 'package:akka_food/features/user_profile/presentation/screens/edit_profile_screen.dart';
import 'package:akka_food/features/user_profile/presentation/screens/profile_screen.dart';

// =============================================================================
// Fake profile repository
// =============================================================================

class FakeProfileRepository implements IProfileRepository {
  UserProfile _profile;

  FakeProfileRepository(this._profile);

  @override
  Future<UserProfile> getProfile(String uid) async => _profile;

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _profile = profile.copyWith(updatedAt: DateTime.now());
    return _profile;
  }

  @override
  Future<String> uploadAvatar(String uid, dynamic imageFile) async =>
      'https://example.com/avatar.jpg';

  @override
  Future<void> removeAvatar(String uid) async {
    _profile = _profile.copyWith(
      avatarUrl:
          'https://storage.googleapis.com/akka-food.appspot.com/avatars/default/placeholder.png',
    );
  }

  @override
  Future<NotificationPreference> getNotificationPrefs(String uid) async =>
      NotificationPreference(
        uid: uid,
        orderUpdates: true,
        promotions: true,
        coinEvents: true,
      );

  @override
  Future<void> updateNotificationPrefs(NotificationPreference prefs) async {}

  @override
  Stream<UserProfile> watchProfile(String uid) async* {
    yield _profile;
  }
}

// =============================================================================
// Shared test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-profile-test',
      email: 'alice@example.com',
      displayName: 'Alice',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

UserProfile _fakeProfile() => UserProfile(
      uid: 'uid-profile-test',
      displayName: 'Alice',
      email: 'alice@example.com',
      phoneNumber: '+22670000001',
      avatarUrl: null,
      updatedAt: DateTime(2024, 6, 1),
    );

// =============================================================================
// App under test
// =============================================================================

/// Shared [GoRouter] instance used across tests so we can navigate
/// programmatically without needing a [BuildContext] after an async gap.
late GoRouter _router;

Widget _buildApp({required FakeProfileRepository fakeRepo}) {
  final fakeUser = _fakeUser();

  return ProviderScope(
    overrides: [
      // Inject the fake profile repository
      profileRepositoryProvider.overrideWith((_) async => fakeRepo),
      // Inject a pre-authenticated user so the router redirects to /home
      currentUserProvider.overrideWith((ref) => fakeUser),
    ],
    child: _AppUnderTest(onRouterCreated: (r) => _router = r),
  );
}

class _AppUnderTest extends ConsumerWidget {
  const _AppUnderTest({required this.onRouterCreated});

  final void Function(GoRouter) onRouterCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    onRouterCreated(router);
    return MaterialApp.router(
      title: 'AKKA Food Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test 1: Profile screen shows display name, email, and phone
  // ---------------------------------------------------------------------------

  testWidgets('ProfileScreen shows display name, email, and phone number',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_fakeProfile());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    // Let the auth guard redirect to /home
    await tester.pumpAndSettle();

    // Navigate to /profile using the router captured during build
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    // Should be on the profile screen
    expect(find.byType(ProfileScreen), findsOneWidget);

    // Display name is shown
    expect(find.text('Alice'), findsWidgets);

    // Email is shown
    expect(find.text('alice@example.com'), findsWidgets);

    // Phone number is shown
    expect(find.text('+22670000001'), findsWidgets);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Tapping "Edit Profile" navigates to EditProfileScreen
  // ---------------------------------------------------------------------------

  testWidgets('Tapping "Edit Profile" navigates to EditProfileScreen',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_fakeProfile());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);

    // Tap the "Edit Profile" navigation tile
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    // Should navigate to EditProfileScreen
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: Editing display name and saving updates the profile
  // ---------------------------------------------------------------------------

  testWidgets('Editing display name and saving updates the profile',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_fakeProfile());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    // Navigate to EditProfileScreen
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);

    // Clear the display name field and enter a new name
    final displayNameField = find.widgetWithText(TextFormField, 'Alice');
    await tester.tap(displayNameField);
    await tester.pump();
    await tester.enterText(displayNameField, 'Alice Updated');
    await tester.pump();

    // Tap "Save Changes"
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    // Should navigate back to ProfileScreen after successful save
    expect(find.byType(ProfileScreen), findsOneWidget);

    // The updated name should be reflected
    expect(find.text('Alice Updated'), findsWidgets);
  });

  // ---------------------------------------------------------------------------
  // Test 4: Validation error shown for display name < 2 chars
  // ---------------------------------------------------------------------------

  testWidgets('Validation error shown when display name is less than 2 chars',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_fakeProfile());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    // Navigate to EditProfileScreen
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);

    // Enter a single character (too short)
    final displayNameField = find.widgetWithText(TextFormField, 'Alice');
    await tester.tap(displayNameField);
    await tester.pump();
    await tester.enterText(displayNameField, 'A');
    await tester.pump();

    // Tap "Save Changes" to trigger validation
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    // Validation error message should appear
    expect(
      find.text('Display name must be at least 2 characters.'),
      findsOneWidget,
    );

    // Should still be on EditProfileScreen (not navigated away)
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });
}
