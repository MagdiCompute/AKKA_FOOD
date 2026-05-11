// integration_test/user_profile_address_test.dart
//
// Task 9.2 — Address management integration tests
//
// Tests that the AddressListScreen displays addresses, allows adding new
// addresses via AddressFormScreen, setting a default address, and deleting
// addresses. Uses FakeAddressRepository injected via ProviderScope overrides.
// No real Firebase connection is made.
//
// The full GoRouter is used so that navigation between AddressListScreen and
// AddressFormScreen works correctly. The router starts at /login but the
// auth guard immediately redirects authenticated users to /home; from there
// the test navigates to /profile/addresses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/core/router/app_router.dart';
import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_address_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/address_notifier.dart';
import 'package:akka_food/features/user_profile/presentation/screens/address_form_screen.dart';
import 'package:akka_food/features/user_profile/presentation/screens/address_list_screen.dart';

// =============================================================================
// Fake address repository
// =============================================================================

class FakeAddressRepository implements IAddressRepository {
  List<DeliveryAddress> _addresses;

  FakeAddressRepository(this._addresses);

  @override
  Future<List<DeliveryAddress>> getAddresses(String uid) async => _addresses;

  @override
  Future<DeliveryAddress> addAddress(DeliveryAddress address) async {
    final newAddress = address.copyWith(
      id: 'addr-${_addresses.length + 1}',
      uid: 'uid-address-test',
      createdAt: DateTime.now(),
    );
    _addresses = [..._addresses, newAddress];
    return newAddress;
  }

  @override
  Future<DeliveryAddress> updateAddress(DeliveryAddress address) async {
    _addresses = [
      for (final a in _addresses)
        if (a.id == address.id) address else a,
    ];
    return address;
  }

  @override
  Future<void> deleteAddress(String uid, String addressId) async {
    _addresses = _addresses.where((a) => a.id != addressId).toList();
  }

  @override
  Future<void> setDefaultAddress(String uid, String addressId) async {
    _addresses = [
      for (final a in _addresses)
        a.copyWith(isDefault: a.id == addressId),
    ];
  }

  @override
  Stream<List<DeliveryAddress>> watchAddresses(String uid) async* {
    yield _addresses;
  }
}

// =============================================================================
// Shared test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-address-test',
      email: 'bob@example.com',
      displayName: 'Bob',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

List<DeliveryAddress> _fakeAddresses() => [
      DeliveryAddress(
        id: 'addr-1',
        uid: 'uid-address-test',
        label: 'Home',
        streetAddress: '123 Main St',
        city: 'Ouagadougou',
        latitude: 12.3647,
        longitude: -1.5332,
        isDefault: true,
        createdAt: DateTime(2024, 1, 1),
      ),
      DeliveryAddress(
        id: 'addr-2',
        uid: 'uid-address-test',
        label: 'Office',
        streetAddress: '456 Work Ave',
        city: 'Bobo-Dioulasso',
        latitude: 11.1770,
        longitude: -4.2979,
        isDefault: false,
        createdAt: DateTime(2024, 2, 1),
      ),
    ];

// =============================================================================
// App under test
// =============================================================================

/// Shared [GoRouter] instance captured during build for programmatic navigation.
late GoRouter _router;

Widget _buildApp({required FakeAddressRepository fakeRepo}) {
  final fakeUser = _fakeUser();

  return ProviderScope(
    overrides: [
      // Inject the fake address repository
      addressRepositoryProvider.overrideWith((_) async => fakeRepo),
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
  // Test 1: Address list screen shows existing addresses
  // ---------------------------------------------------------------------------

  testWidgets('AddressListScreen shows existing addresses',
      (WidgetTester tester) async {
    final fakeRepo = FakeAddressRepository(_fakeAddresses());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile/addresses
    _router.go(AppRoutes.addresses);
    await tester.pumpAndSettle();

    // Should be on the address list screen
    expect(find.byType(AddressListScreen), findsOneWidget);

    // Both addresses should be visible
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('123 Main St, Ouagadougou'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    expect(find.text('456 Work Ave, Bobo-Dioulasso'), findsOneWidget);

    // "Default" badge should be shown for the home address
    expect(find.text('Default'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Tapping "+" navigates to AddressFormScreen
  // ---------------------------------------------------------------------------

  testWidgets('Tapping "+" FAB navigates to AddressFormScreen',
      (WidgetTester tester) async {
    final fakeRepo = FakeAddressRepository(_fakeAddresses());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile/addresses
    _router.go(AppRoutes.addresses);
    await tester.pumpAndSettle();

    expect(find.byType(AddressListScreen), findsOneWidget);

    // Tap the floating action button
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Should navigate to AddressFormScreen
    expect(find.byType(AddressFormScreen), findsOneWidget);
    expect(find.text('Add Address'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: Filling form and saving adds a new address
  // ---------------------------------------------------------------------------

  testWidgets('Filling form and saving adds a new address',
      (WidgetTester tester) async {
    final fakeRepo = FakeAddressRepository(_fakeAddresses());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile/addresses
    _router.go(AppRoutes.addresses);
    await tester.pumpAndSettle();

    // Navigate to AddressFormScreen
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddressFormScreen), findsOneWidget);

    // Fill in the form fields using hint text to locate them
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Home, Office, Other'),
      'Gym',
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. 12 Rue de la Paix'),
      '789 Fitness Blvd',
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Ouagadougou'),
      'Koudougou',
    );
    await tester.pump();

    // Tap "Add Address" button
    await tester.tap(find.widgetWithText(FilledButton, 'Add Address'));
    await tester.pumpAndSettle();

    // Should navigate back to AddressListScreen
    expect(find.byType(AddressListScreen), findsOneWidget);

    // The new address should be visible
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('789 Fitness Blvd, Koudougou'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 4: Tapping "Set as Default" marks address as default
  // ---------------------------------------------------------------------------

  testWidgets('Tapping "Set as Default" marks address as default',
      (WidgetTester tester) async {
    final fakeRepo = FakeAddressRepository(_fakeAddresses());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile/addresses
    _router.go(AppRoutes.addresses);
    await tester.pumpAndSettle();

    expect(find.byType(AddressListScreen), findsOneWidget);

    // Initially, "Home" is the default — one "Default" badge visible
    expect(find.text('Default'), findsOneWidget);

    // Find the "Set as Default" button for the Office address
    final setDefaultButton = find.widgetWithText(TextButton, 'Set as Default');
    expect(setDefaultButton, findsOneWidget);

    await tester.tap(setDefaultButton);
    await tester.pumpAndSettle();

    // Now "Office" should be the default — still one "Default" badge
    expect(find.text('Default'), findsOneWidget);

    // The "Set as Default" button should now appear for Home instead
    expect(find.widgetWithText(TextButton, 'Set as Default'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 5: Swiping to delete removes a non-default address
  // ---------------------------------------------------------------------------

  testWidgets('Swiping to delete removes a non-default address',
      (WidgetTester tester) async {
    final fakeRepo = FakeAddressRepository(_fakeAddresses());

    await tester.pumpWidget(_buildApp(fakeRepo: fakeRepo));
    await tester.pumpAndSettle();

    // Navigate to /profile/addresses
    _router.go(AppRoutes.addresses);
    await tester.pumpAndSettle();

    expect(find.byType(AddressListScreen), findsOneWidget);

    // Both addresses should be visible initially
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);

    // Swipe the "Office" address tile to the left to trigger delete
    await tester.drag(find.text('Office'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // A confirmation dialog should appear
    expect(find.text('Delete Address'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete this address?'),
      findsOneWidget,
    );

    // Confirm deletion
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    // "Office" should no longer be visible
    expect(find.text('Office'), findsNothing);
    expect(find.text('456 Work Ave, Bobo-Dioulasso'), findsNothing);

    // "Home" should still be visible
    expect(find.text('Home'), findsOneWidget);
  });
}
