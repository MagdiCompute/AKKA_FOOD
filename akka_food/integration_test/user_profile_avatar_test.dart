// integration_test/user_profile_avatar_test.dart
//
// Task 9.3 — Avatar upload and removal integration tests
//
// Tests the AvatarPickerWidget UI states: camera icon overlay, bottom sheet
// options, "Remove Photo" visibility based on avatar URL. Actual image picking
// cannot be tested in integration tests (requires device interaction), so
// tests focus on UI state only.
//
// Uses FakeProfileRepository injected via ProviderScope overrides.
// No real Firebase connection is made.
//
// The full GoRouter is used. The router starts at /login but the auth guard
// immediately redirects authenticated users to /home; from there the test
// navigates to /profile.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/core/router/app_router.dart';
import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/user_profile/data/repositories/profile_repository.dart'
    show kDefaultAvatarUrl;
import 'package:akka_food/features/user_profile/domain/entities/notification_preference.dart';
import 'package:akka_food/features/user_profile/domain/entities/user_profile.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_profile_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/profile_notifier.dart';
import 'package:akka_food/features/user_profile/presentation/screens/profile_screen.dart';
import 'package:akka_food/features/user_profile/presentation/widgets/avatar_picker_widget.dart';

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
  Future<String> uploadAvatar(String uid, dynamic imageFile) async {
    const newUrl = 'https://example.com/new-avatar.jpg';
    _profile = _profile.copyWith(avatarUrl: newUrl);
    return newUrl;
  }

  @override
  Future<void> removeAvatar(String uid) async {
    _profile = _profile.copyWith(avatarUrl: kDefaultAvatarUrl);
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
      uid: 'uid-avatar-test',
      email: 'carol@example.com',
      displayName: 'Carol',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

UserProfile _profileWithRealAvatar() => UserProfile(
      uid: 'uid-avatar-test',
      displayName: 'Carol',
      email: 'carol@example.com',
      phoneNumber: null,
      avatarUrl: 'https://example.com/carol-avatar.jpg',
      updatedAt: DateTime(2024, 6, 1),
    );

UserProfile _profileWithDefaultAvatar() => UserProfile(
      uid: 'uid-avatar-test',
      displayName: 'Carol',
      email: 'carol@example.com',
      phoneNumber: null,
      avatarUrl: kDefaultAvatarUrl,
      updatedAt: DateTime(2024, 6, 1),
    );

UserProfile _profileWithNoAvatar() => UserProfile(
      uid: 'uid-avatar-test',
      displayName: 'Carol',
      email: 'carol@example.com',
      phoneNumber: null,
      avatarUrl: null,
      updatedAt: DateTime(2024, 6, 1),
    );

// =============================================================================
// App under test
// =============================================================================

/// Shared [GoRouter] instance captured during build for programmatic navigation.
late GoRouter _router;

Widget _buildApp({required FakeProfileRepository fakeRepo}) {
  final fakeUser = _fakeUser();

  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWith((_) async => fakeRepo),
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
  // Test 1: Avatar picker widget renders with camera icon overlay
  // ---------------------------------------------------------------------------

  testWidgets('AvatarPickerWidget renders with camera icon overlay',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_profileWithNoAvatar());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    // Should be on the profile screen
    expect(find.byType(ProfileScreen), findsOneWidget);

    // AvatarPickerWidget should be present
    expect(find.byType(AvatarPickerWidget), findsOneWidget);

    // Camera icon overlay should be visible
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Tapping avatar opens bottom sheet with photo options
  // ---------------------------------------------------------------------------

  testWidgets('Tapping avatar opens bottom sheet with photo options',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_profileWithNoAvatar());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPickerWidget), findsOneWidget);

    // Tap the avatar picker widget
    await tester.tap(find.byType(AvatarPickerWidget));
    await tester.pumpAndSettle();

    // Bottom sheet should appear with photo options
    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: "Remove Photo" option appears when a real avatar URL is set
  // ---------------------------------------------------------------------------

  testWidgets(
      '"Remove Photo" option appears in bottom sheet when real avatar is set',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_profileWithRealAvatar());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPickerWidget), findsOneWidget);

    // Tap the avatar picker widget to open the bottom sheet
    await tester.tap(find.byType(AvatarPickerWidget));
    await tester.pumpAndSettle();

    // Bottom sheet should show all options including "Remove Photo"
    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Remove Photo'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 4: "Remove Photo" option is hidden when avatar is the default placeholder
  // ---------------------------------------------------------------------------

  testWidgets(
      '"Remove Photo" option is hidden when avatar is the default placeholder',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_profileWithDefaultAvatar());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPickerWidget), findsOneWidget);

    // Tap the avatar picker widget to open the bottom sheet
    await tester.tap(find.byType(AvatarPickerWidget));
    await tester.pumpAndSettle();

    // Bottom sheet should show photo options but NOT "Remove Photo"
    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Remove Photo'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Test 5: "Remove Photo" option is hidden when no avatar is set (null URL)
  // ---------------------------------------------------------------------------

  testWidgets(
      '"Remove Photo" option is hidden when no avatar is set (null URL)',
      (WidgetTester tester) async {
    final fakeRepo = FakeProfileRepository(_profileWithNoAvatar());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPickerWidget), findsOneWidget);

    // Tap the avatar picker widget to open the bottom sheet
    await tester.tap(find.byType(AvatarPickerWidget));
    await tester.pumpAndSettle();

    // "Remove Photo" should not appear when there is no real avatar
    expect(find.text('Remove Photo'), findsNothing);
  });
}
