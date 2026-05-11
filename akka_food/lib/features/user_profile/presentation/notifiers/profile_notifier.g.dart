// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileRepositoryHash() => r'441d817d710cbe15513ced0140496ebe16dce139';

/// Provides the concrete [ProfileRepository] bound to [IProfileRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreProfileDataSource] — Firestore reads/writes
/// - [FirebaseAvatarStorageClient] wrapping [FirebaseStorageDataSource] — Storage
/// - [ImageCompressionService] — avatar compression
/// - [HiveProfileCache] — local 5-minute TTL cache
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider =
    AutoDisposeFutureProvider<IProfileRepository>.internal(
      profileRepository,
      name: r'profileRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRepositoryRef = AutoDisposeFutureProviderRef<IProfileRepository>;
String _$profileNotifierHash() => r'c3434dedeadee8693d2aceedb84ce0db9dfcba34';

/// Manages the [UserProfile] state for the UI layer.
///
/// Uses the stale-while-revalidate (SWR) pattern via
/// [IProfileRepository.watchProfile]: the cached profile is emitted
/// immediately, then fresh Firestore data is fetched in the background.
///
/// Exposes mutation methods:
/// - [updateProfile] — persists display name, email, and phone changes
/// - [uploadAvatar] — compresses, uploads, and links a new avatar image
/// - [removeAvatar] — resets the avatar URL to the default placeholder
///
/// The notifier throws [StateError] when called without an authenticated user.
///
/// Copied from [ProfileNotifier].
@ProviderFor(ProfileNotifier)
final profileNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ProfileNotifier, UserProfile?>.internal(
      ProfileNotifier.new,
      name: r'profileNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProfileNotifier = AutoDisposeAsyncNotifier<UserProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
