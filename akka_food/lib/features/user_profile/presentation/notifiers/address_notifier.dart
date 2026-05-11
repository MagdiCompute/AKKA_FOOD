import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/presentation/notifiers/auth_notifier.dart';
import '../../data/datasources/firestore_address_data_source.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../data/repositories/address_repository.dart';
import '../../domain/entities/delivery_address.dart';
import '../../domain/repositories/i_address_repository.dart';

part 'address_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [AddressRepository] bound to [IAddressRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreAddressDataSource] — Firestore CRUD on `/users/{uid}/addresses`
/// - [HiveProfileCache] — local 5-minute TTL cache for the address list
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
Future<IAddressRepository> addressRepository(Ref ref) async {
  final cache = await HiveProfileCache.open();
  return AddressRepository(
    firestoreDataSource: FirestoreAddressDataSource(),
    cache: cache,
  );
}

// ---------------------------------------------------------------------------
// AddressNotifier
// ---------------------------------------------------------------------------

/// Manages the [DeliveryAddress] list state for the UI layer.
///
/// Uses the stale-while-revalidate (SWR) pattern via
/// [IAddressRepository.watchAddresses]: the cached address list is emitted
/// immediately, then fresh Firestore data is fetched in the background.
///
/// Exposes mutation methods:
/// - [addAddress] — persists a new address (enforces 10-address limit)
/// - [updateAddress] — persists changes to an existing address
/// - [deleteAddress] — permanently removes an address
/// - [setDefault] — atomically marks an address as the default
///
/// The notifier returns an empty list when no user is signed in.
@riverpod
class AddressNotifier extends _$AddressNotifier {
  // ---------------------------------------------------------------------------
  // build — SWR stream
  // ---------------------------------------------------------------------------

  /// Initialises the notifier by subscribing to the SWR address stream.
  ///
  /// Returns an empty list when no user is signed in.
  @override
  Future<List<DeliveryAddress>> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return [];

    final repository = await ref.watch(addressRepositoryProvider.future);

    // Collect the SWR stream into a single Future that resolves to the
    // latest emitted value (fresh data after stale-while-revalidate).
    List<DeliveryAddress> latest = [];
    await for (final addresses in repository.watchAddresses(currentUser.uid)) {
      latest = addresses;
      // Update state with each emission so the UI reflects stale data
      // immediately while fresh data loads.
      state = AsyncData(addresses);
    }
    return latest;
  }

  // ---------------------------------------------------------------------------
  // addAddress
  // ---------------------------------------------------------------------------

  /// Persists a new [address] and refreshes the address list state.
  ///
  /// Throws a [StateError] if the 10-address limit has been reached.
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirements 4.1, 4.2.
  Future<void> addAddress(DeliveryAddress address) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError('Cannot add address: no authenticated user.');
    }

    final repository = await ref.read(addressRepositoryProvider.future);

    final previous = state;
    state = const AsyncLoading<List<DeliveryAddress>>()
        .copyWithPrevious(previous);

    try {
      final saved = await repository.addAddress(address);
      final currentList = previous.valueOrNull ?? [];
      state = AsyncData([...currentList, saved]);
    } catch (e, st) {
      state =
          AsyncError<List<DeliveryAddress>>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // updateAddress
  // ---------------------------------------------------------------------------

  /// Persists changes to an existing [address] and refreshes the state.
  ///
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirement 4.3.
  Future<void> updateAddress(DeliveryAddress address) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError('Cannot update address: no authenticated user.');
    }

    final repository = await ref.read(addressRepositoryProvider.future);

    final previous = state;
    state = const AsyncLoading<List<DeliveryAddress>>()
        .copyWithPrevious(previous);

    try {
      final updated = await repository.updateAddress(address);
      final currentList = previous.valueOrNull ?? [];
      state = AsyncData([
        for (final a in currentList)
          if (a.id == updated.id) updated else a,
      ]);
    } catch (e, st) {
      state =
          AsyncError<List<DeliveryAddress>>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // deleteAddress
  // ---------------------------------------------------------------------------

  /// Permanently removes the address identified by [addressId] and refreshes
  /// the state.
  ///
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirement 4.4.
  Future<void> deleteAddress(String addressId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError('Cannot delete address: no authenticated user.');
    }

    final repository = await ref.read(addressRepositoryProvider.future);

    final previous = state;
    state = const AsyncLoading<List<DeliveryAddress>>()
        .copyWithPrevious(previous);

    try {
      await repository.deleteAddress(currentUser.uid, addressId);
      final currentList = previous.valueOrNull ?? [];
      state = AsyncData(
        currentList.where((a) => a.id != addressId).toList(),
      );
    } catch (e, st) {
      state =
          AsyncError<List<DeliveryAddress>>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // setDefault
  // ---------------------------------------------------------------------------

  /// Atomically marks [addressId] as the default address and clears the
  /// default flag on all other addresses, then refreshes the state.
  ///
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirement 4.5.
  Future<void> setDefault(String addressId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError('Cannot set default address: no authenticated user.');
    }

    final repository = await ref.read(addressRepositoryProvider.future);

    final previous = state;
    state = const AsyncLoading<List<DeliveryAddress>>()
        .copyWithPrevious(previous);

    try {
      await repository.setDefaultAddress(currentUser.uid, addressId);
      final currentList = previous.valueOrNull ?? [];
      // Reflect the new default locally: set isDefault=true on the target,
      // isDefault=false on all others.
      state = AsyncData([
        for (final a in currentList)
          a.copyWith(isDefault: a.id == addressId),
      ]);
    } catch (e, st) {
      state =
          AsyncError<List<DeliveryAddress>>(e, st).copyWithPrevious(previous);
    }
  }
}
