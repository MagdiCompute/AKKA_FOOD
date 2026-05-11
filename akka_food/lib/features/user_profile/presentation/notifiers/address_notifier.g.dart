// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$addressRepositoryHash() => r'62401b2ced7ba67ce1bc27ea06c3cb0a25b80929';

/// Provides the concrete [AddressRepository] bound to [IAddressRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreAddressDataSource] — Firestore CRUD on `/users/{uid}/addresses`
/// - [HiveProfileCache] — local 5-minute TTL cache for the address list
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [addressRepository].
@ProviderFor(addressRepository)
final addressRepositoryProvider =
    AutoDisposeFutureProvider<IAddressRepository>.internal(
      addressRepository,
      name: r'addressRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$addressRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AddressRepositoryRef = AutoDisposeFutureProviderRef<IAddressRepository>;
String _$addressNotifierHash() => r'08dc6e51792c4ed573977864d318526cf26b31e9';

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
///
/// Copied from [AddressNotifier].
@ProviderFor(AddressNotifier)
final addressNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      AddressNotifier,
      List<DeliveryAddress>
    >.internal(
      AddressNotifier.new,
      name: r'addressNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$addressNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AddressNotifier = AutoDisposeAsyncNotifier<List<DeliveryAddress>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
