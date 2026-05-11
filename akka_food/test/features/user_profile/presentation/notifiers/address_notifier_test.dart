import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_address_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/address_notifier.dart';

// =============================================================================
// Test fixtures
// =============================================================================

final _fakeUser = AppUser(
  uid: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
  isVerified: true,
  isDeactivated: false,
  createdAt: DateTime(2024, 1, 1),
  linkedProviders: const ['password'],
);

DeliveryAddress _fakeAddress({
  String id = 'addr-1',
  String label = 'Home',
  bool isDefault = false,
}) {
  return DeliveryAddress(
    id: id,
    uid: 'test-uid',
    label: label,
    streetAddress: '123 Main St',
    city: 'Ouagadougou',
    isDefault: isDefault,
    createdAt: DateTime(2024, 1, 1),
  );
}

// =============================================================================
// FakeAddressRepository
// =============================================================================

class FakeAddressRepository implements IAddressRepository {
  List<DeliveryAddress> addresses;

  bool throwOnAddAddress = false;
  bool throwOnUpdateAddress = false;
  bool throwOnDeleteAddress = false;
  bool throwOnSetDefaultAddress = false;

  DeliveryAddress? lastAddedAddress;
  DeliveryAddress? lastUpdatedAddress;
  String? lastDeletedAddressId;
  String? lastDefaultAddressId;

  FakeAddressRepository({List<DeliveryAddress>? addresses})
      : addresses = addresses ?? [];

  @override
  Future<List<DeliveryAddress>> getAddresses(String uid) async => addresses;

  @override
  Future<DeliveryAddress> addAddress(DeliveryAddress address) async {
    if (throwOnAddAddress) throw Exception('addAddress failed');
    lastAddedAddress = address;
    final saved = address.copyWith(id: 'addr-new');
    addresses = [...addresses, saved];
    return saved;
  }

  @override
  Future<DeliveryAddress> updateAddress(DeliveryAddress address) async {
    if (throwOnUpdateAddress) throw Exception('updateAddress failed');
    lastUpdatedAddress = address;
    addresses = [
      for (final a in addresses)
        if (a.id == address.id) address else a,
    ];
    return address;
  }

  @override
  Future<void> deleteAddress(String uid, String addressId) async {
    if (throwOnDeleteAddress) throw Exception('deleteAddress failed');
    lastDeletedAddressId = addressId;
    addresses = addresses.where((a) => a.id != addressId).toList();
  }

  @override
  Future<void> setDefaultAddress(String uid, String addressId) async {
    if (throwOnSetDefaultAddress) throw Exception('setDefaultAddress failed');
    lastDefaultAddressId = addressId;
    addresses = [
      for (final a in addresses) a.copyWith(isDefault: a.id == addressId),
    ];
  }

  @override
  Stream<List<DeliveryAddress>> watchAddresses(String uid) {
    return Stream.value(addresses);
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('AddressNotifier', () {
    // -------------------------------------------------------------------------
    // build()
    // -------------------------------------------------------------------------

    group('build()', () {
      test('returns address list from repository when user is signed in',
          () async {
        final addresses = [
          _fakeAddress(id: 'addr-1', label: 'Home', isDefault: true),
          _fakeAddress(id: 'addr-2', label: 'Work'),
        ];
        final repo = FakeAddressRepository(addresses: addresses);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(addressNotifierProvider.future);

        expect(result, hasLength(2));
        expect(result.first.label, equals('Home'));
        expect(result.first.isDefault, isTrue);
      });

      test('returns empty list when no user is signed in', () async {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            addressRepositoryProvider.overrideWith(
              (_) async => FakeAddressRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(addressNotifierProvider.future);

        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // addAddress()
    // -------------------------------------------------------------------------

    group('addAddress()', () {
      test('appends new address to state on success', () async {
        final existing = _fakeAddress(id: 'addr-1', label: 'Home');
        final repo = FakeAddressRepository(addresses: [existing]);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        final newAddress = _fakeAddress(id: 'addr-new', label: 'Office');
        await container
            .read(addressNotifierProvider.notifier)
            .addAddress(newAddress);

        final state = container.read(addressNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!, hasLength(2));
        expect(state.value!.last.label, equals('Office'));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final existing = _fakeAddress(id: 'addr-1', label: 'Home');
        final repo = FakeAddressRepository(addresses: [existing])
          ..throwOnAddAddress = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        await container
            .read(addressNotifierProvider.notifier)
            .addAddress(_fakeAddress(id: 'addr-new', label: 'Office'));

        final state = container.read(addressNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull, hasLength(1));
        expect(state.valueOrNull!.first.label, equals('Home'));
      });

      test('state goes through loading before settling', () async {
        final repo = FakeAddressRepository();
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        final states = <AsyncValue<List<DeliveryAddress>>>[];
        final sub = container.listen(
          addressNotifierProvider,
          (_, next) => states.add(next),
        );

        await container
            .read(addressNotifierProvider.notifier)
            .addAddress(_fakeAddress(label: 'New'));

        sub.close();

        expect(states.any((s) => s.isLoading), isTrue);
        expect(states.last.hasValue, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // updateAddress()
    // -------------------------------------------------------------------------

    group('updateAddress()', () {
      test('replaces updated address in state on success', () async {
        final original = _fakeAddress(id: 'addr-1', label: 'Home');
        final repo = FakeAddressRepository(addresses: [original]);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        final updated = original.copyWith(label: 'Updated Home');
        await container
            .read(addressNotifierProvider.notifier)
            .updateAddress(updated);

        final state = container.read(addressNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!, hasLength(1));
        expect(state.value!.first.label, equals('Updated Home'));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final original = _fakeAddress(id: 'addr-1', label: 'Home');
        final repo = FakeAddressRepository(addresses: [original])
          ..throwOnUpdateAddress = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        await container
            .read(addressNotifierProvider.notifier)
            .updateAddress(original.copyWith(label: 'Updated'));

        final state = container.read(addressNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!.first.label, equals('Home'));
      });
    });

    // -------------------------------------------------------------------------
    // deleteAddress()
    // -------------------------------------------------------------------------

    group('deleteAddress()', () {
      test('removes address from state on success', () async {
        final addr1 = _fakeAddress(id: 'addr-1', label: 'Home');
        final addr2 = _fakeAddress(id: 'addr-2', label: 'Work');
        final repo = FakeAddressRepository(addresses: [addr1, addr2]);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        await container
            .read(addressNotifierProvider.notifier)
            .deleteAddress('addr-1');

        final state = container.read(addressNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!, hasLength(1));
        expect(state.value!.first.id, equals('addr-2'));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final addr1 = _fakeAddress(id: 'addr-1', label: 'Home');
        final repo = FakeAddressRepository(addresses: [addr1])
          ..throwOnDeleteAddress = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        await container
            .read(addressNotifierProvider.notifier)
            .deleteAddress('addr-1');

        final state = container.read(addressNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!, hasLength(1));
      });
    });

    // -------------------------------------------------------------------------
    // setDefault()
    // -------------------------------------------------------------------------

    group('setDefault()', () {
      test('marks target address as default and clears others', () async {
        final addr1 = _fakeAddress(id: 'addr-1', label: 'Home', isDefault: true);
        final addr2 = _fakeAddress(id: 'addr-2', label: 'Work', isDefault: false);
        final repo = FakeAddressRepository(addresses: [addr1, addr2]);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        await container
            .read(addressNotifierProvider.notifier)
            .setDefault('addr-2');

        final state = container.read(addressNotifierProvider);
        expect(state.hasValue, isTrue);
        final list = state.value!;
        expect(list.firstWhere((a) => a.id == 'addr-2').isDefault, isTrue);
        expect(list.firstWhere((a) => a.id == 'addr-1').isDefault, isFalse);
        expect(repo.lastDefaultAddressId, equals('addr-2'));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final addr1 = _fakeAddress(id: 'addr-1', isDefault: true);
        final addr2 = _fakeAddress(id: 'addr-2', isDefault: false);
        final repo = FakeAddressRepository(addresses: [addr1, addr2])
          ..throwOnSetDefaultAddress = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            addressRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addressNotifierProvider.future);

        await container
            .read(addressNotifierProvider.notifier)
            .setDefault('addr-2');

        final state = container.read(addressNotifierProvider);
        expect(state.hasError, isTrue);
        // Previous default is preserved
        expect(
          state.valueOrNull!.firstWhere((a) => a.id == 'addr-1').isDefault,
          isTrue,
        );
      });
    });
  });
}
