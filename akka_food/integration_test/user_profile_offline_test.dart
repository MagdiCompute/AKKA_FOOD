// integration_test/user_profile_offline_test.dart
//
// Task 9.4 — Offline profile display from cache integration tests
//
// Tests that the ProfileScreen and AddressListScreen display stale cached data
// when the network is unavailable, and that a connectivity banner is shown.
//
// The fake repositories are configured to simulate the SWR pattern under
// network failure:
//   1. watchProfile() / watchAddresses() yield stale cached data immediately.
//   2. Then throw a SocketException (simulating the Firestore fetch failure).
//
// The ProfileNotifier / AddressNotifier will be in AsyncData state (from the
// stale yield) but the hasError flag is set after the stream throws, which
// causes the connectivity banner to appear in ProfileScreen.
//
// Uses FakeOfflineProfileRepository and FakeOfflineAddressRepository injected
// via ProviderScope overrides. No real Firebase connection is made.

import 'dart:io';

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
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:akka_food/features/user_profile/domain/entities/notification_preference.dart';
import 'package:akka_food/features/user_profile/domain/entities/user_profile.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_address_repository.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_profile_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/address_notifier.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/profile_notifier.dart';
import 'package:akka_food/features/user_profile/presentation/screens/address_list_screen.dart';
import 'package:akka_food/features/user_profile/presentation/screens/profile_screen.dart';

// =============================================================================
// Fake offline profile repository
//
// Simulates the SWR pattern under network failure:
//   - watchProfile() yields stale cached data, then throws SocketException.
//   - getProfile() throws SocketException (no fresh data available).
// =============================================================================

class FakeOfflineProfileRepository implements IProfileRepository {
  final UserProfile _cachedProfile;

  FakeOfflineProfileRepository(this._cachedProfile);

  @override
  Future<UserProfile> getProfile(String uid) async {
    throw const SocketException('Network unavailable');
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    throw const SocketException('Network unavailable');
  }

  @override
  Future<String> uploadAvatar(String uid, dynamic imageFile) async {
    throw const SocketException('Network unavailable');
  }

  @override
  Future<void> removeAvatar(String uid) async {
    throw const SocketException('Network unavailable');
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

  /// Emits stale cached data first, then throws a SocketException.
  ///
  /// This mirrors the real ProfileRepository.watchProfile() SWR behaviour:
  /// - Stale cache is yielded immediately (ProfileNotifier enters AsyncData).
  /// - The Firestore fetch fails; since stale data was already emitted the
  ///   stream throws, which causes ProfileNotifier to enter AsyncError while
  ///   preserving the previous value — triggering the connectivity banner.
  @override
  Stream<UserProfile> watchProfile(String uid) async* {
    yield _cachedProfile;
    throw const SocketException('Network unavailable');
  }
}

// =============================================================================
// Fake offline address repository
//
// Simulates the SWR pattern under network failure:
//   - watchAddresses() yields stale cached data, then throws SocketException.
// =============================================================================

class FakeOfflineAddressRepository implements IAddressRepository {
  final List<DeliveryAddress> _cachedAddresses;

  FakeOfflineAddressRepository(this._cachedAddresses);

  @override
  Future<List<DeliveryAddress>> getAddresses(String uid) async {
    throw const SocketException('Network unavailable');
  }

  @override
  Future<DeliveryAddress> addAddress(DeliveryAddress address) async {
    throw const SocketException('Network unavailable');
  }

  @override
  Future<DeliveryAddress> updateAddress(DeliveryAddress address) async {
    throw const SocketException('Network unavailable');
  }

  @override
  Future<void> deleteAddress(String uid, String addressId) async {
    throw const SocketException('Network unavailable');
  }

  @override
  Future<void> setDefaultAddress(String uid, String addressId) async {
    throw const SocketException('Network unavailable');
  }

  /// Emits stale cached data first, then throws a SocketException.
  ///
  /// Mirrors the real AddressRepository.watchAddresses() SWR behaviour.
  @override
  Stream<List<DeliveryAddress>> watchAddresses(String uid) async* {
    yield _cachedAddresses;
    throw const SocketException('Network unavailable');
  }
}

// =============================================================================
// Shared test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-offline-test',
      email: 'dave@example.com',
      displayName: 'Dave',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

UserProfile _staleCachedProfile() => UserProfile(
      uid: 'uid-offline-test',
      displayName: 'Dave (cached)',
      email: 'dave@example.com',
      phoneNumber: '+22670000099',
      avatarUrl: kDefaultAvatarUrl,
      updatedAt: DateTime(2024, 5, 1),
    );

List<DeliveryAddress> _staleCachedAddresses() => [
      DeliveryAddress(
        id: 'addr-cached-1',
        uid: 'uid-offline-test',
        label: 'Home (cached)',
        streetAddress: '1 Cached Street',
        city: 'Ouagadougou',
        latitude: null,
        longitude: null,
        isDefault: true,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

// =============================================================================
// App under test — profile screen
// =============================================================================

/// Shared [GoRouter] instance captured during build for programmatic navigation.
late GoRouter _profileRouter;

Widget _buildProfileApp({
  required FakeOfflineProfileRepository fakeProfileRepo,
}) {
  final fakeUser = _fakeUser();

  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWith((_) async => fakeProfileRepo),
      currentUserProvider.overrideWith((ref) => fakeUser),
    ],
    child: _ProfileAppUnderTest(onRouterCreated: (r) => _profileRouter = r),
  );
}

class _ProfileAppUnderTest extends ConsumerWidget {
  const _ProfileAppUnderTest({required this.onRouterCreated});

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
// App under test — address list screen
// =============================================================================

/// Shared [GoRouter] instance captured during build for programmatic navigation.
late GoRouter _addressRouter;

Widget _buildAddressApp({
  required FakeOfflineAddressRepository fakeAddressRepo,
}) {
  final fakeUser = _fakeUser();

  return ProviderScope(
    overrides: [
      addressRepositoryProvider.overrideWith((_) async => fakeAddressRepo),
      currentUserProvider.overrideWith((ref) => fakeUser),
    ],
    child: _AddressAppUnderTest(onRouterCreated: (r) => _addressRouter = r),
  );
}

class _AddressAppUnderTest extends ConsumerWidget {
  const _AddressAppUnderTest({required this.onRouterCreated});

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
  // Test 1: Profile screen shows stale cached data when network is unavailable
  // ---------------------------------------------------------------------------

  testWidgets(
      'ProfileScreen shows stale cached data when network is unavailable',
      (WidgetTester tester) async {
    final fakeProfileRepo =
        FakeOfflineProfileRepository(_staleCachedProfile());

    await tester.pumpWidget(_buildProfileApp(fakeProfileRepo: fakeProfileRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _profileRouter.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    // Should be on the profile screen
    expect(find.byType(ProfileScreen), findsOneWidget);

    // Stale cached data should be displayed
    expect(find.text('Dave (cached)'), findsWidgets);
    expect(find.text('dave@example.com'), findsWidgets);
    expect(find.text('+22670000099'), findsWidgets);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Connectivity banner is shown when displaying stale data
  // ---------------------------------------------------------------------------

  testWidgets(
      'Connectivity banner is shown on ProfileScreen when network is unavailable',
      (WidgetTester tester) async {
    final fakeProfileRepo =
        FakeOfflineProfileRepository(_staleCachedProfile());

    await tester.pumpWidget(_buildProfileApp(fakeProfileRepo: fakeProfileRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile
    _profileRouter.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);

    // The connectivity banner should be visible
    expect(
      find.text("You're offline. Showing cached profile data."),
      findsOneWidget,
    );

    // The wifi_off icon should be visible in the banner
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: Address list shows stale cached data when network is unavailable
  // ---------------------------------------------------------------------------

  testWidgets(
      'AddressListScreen shows stale cached data when network is unavailable',
      (WidgetTester tester) async {
    final fakeAddressRepo =
        FakeOfflineAddressRepository(_staleCachedAddresses());

    await tester.pumpWidget(_buildAddressApp(fakeAddressRepo: fakeAddressRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile/addresses
    _addressRouter.go(AppRoutes.addresses);
    await tester.pumpAndSettle();

    // Should be on the address list screen
    expect(find.byType(AddressListScreen), findsOneWidget);

    // Stale cached address should be displayed
    expect(find.text('Home (cached)'), findsOneWidget);
    expect(find.text('1 Cached Street, Ouagadougou'), findsOneWidget);

    // Default badge should be shown
    expect(find.text('Default'), findsOneWidget);
  });
}
