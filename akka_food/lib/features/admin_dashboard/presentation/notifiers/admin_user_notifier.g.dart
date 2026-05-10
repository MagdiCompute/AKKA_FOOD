// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminUserRepositoryHash() =>
    r'1fc3995619b8c513459b6dc427d7924ce3917786';

/// See also [adminUserRepository].
@ProviderFor(adminUserRepository)
final adminUserRepositoryProvider =
    AutoDisposeProvider<IAdminUserRepository>.internal(
      adminUserRepository,
      name: r'adminUserRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminUserRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminUserRepositoryRef = AutoDisposeProviderRef<IAdminUserRepository>;
String _$adminUserDetailHash() => r'0a7c5993950eb82bcc9cf26c73c55230088c3a8a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Fetches a single user and their order history for the detail screen.
///
/// Keyed by [userId] so each user gets its own cached provider instance.
///
/// Copied from [adminUserDetail].
@ProviderFor(adminUserDetail)
const adminUserDetailProvider = AdminUserDetailFamily();

/// Fetches a single user and their order history for the detail screen.
///
/// Keyed by [userId] so each user gets its own cached provider instance.
///
/// Copied from [adminUserDetail].
class AdminUserDetailFamily extends Family<AsyncValue<AdminUserDetailState>> {
  /// Fetches a single user and their order history for the detail screen.
  ///
  /// Keyed by [userId] so each user gets its own cached provider instance.
  ///
  /// Copied from [adminUserDetail].
  const AdminUserDetailFamily();

  /// Fetches a single user and their order history for the detail screen.
  ///
  /// Keyed by [userId] so each user gets its own cached provider instance.
  ///
  /// Copied from [adminUserDetail].
  AdminUserDetailProvider call(String userId) {
    return AdminUserDetailProvider(userId);
  }

  @override
  AdminUserDetailProvider getProviderOverride(
    covariant AdminUserDetailProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adminUserDetailProvider';
}

/// Fetches a single user and their order history for the detail screen.
///
/// Keyed by [userId] so each user gets its own cached provider instance.
///
/// Copied from [adminUserDetail].
class AdminUserDetailProvider
    extends AutoDisposeFutureProvider<AdminUserDetailState> {
  /// Fetches a single user and their order history for the detail screen.
  ///
  /// Keyed by [userId] so each user gets its own cached provider instance.
  ///
  /// Copied from [adminUserDetail].
  AdminUserDetailProvider(String userId)
    : this._internal(
        (ref) => adminUserDetail(ref as AdminUserDetailRef, userId),
        from: adminUserDetailProvider,
        name: r'adminUserDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$adminUserDetailHash,
        dependencies: AdminUserDetailFamily._dependencies,
        allTransitiveDependencies:
            AdminUserDetailFamily._allTransitiveDependencies,
        userId: userId,
      );

  AdminUserDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<AdminUserDetailState> Function(AdminUserDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdminUserDetailProvider._internal(
        (ref) => create(ref as AdminUserDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AdminUserDetailState> createElement() {
    return _AdminUserDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminUserDetailProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdminUserDetailRef on AutoDisposeFutureProviderRef<AdminUserDetailState> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _AdminUserDetailProviderElement
    extends AutoDisposeFutureProviderElement<AdminUserDetailState>
    with AdminUserDetailRef {
  _AdminUserDetailProviderElement(super.provider);

  @override
  String get userId => (origin as AdminUserDetailProvider).userId;
}

String _$adminUserNotifierHash() => r'b5392b004342613f0ae1aa8d249d3cf2dc7b49b7';

/// See also [AdminUserNotifier].
@ProviderFor(AdminUserNotifier)
final adminUserNotifierProvider =
    AutoDisposeNotifierProvider<
      AdminUserNotifier,
      AsyncValue<AdminUserState>
    >.internal(
      AdminUserNotifier.new,
      name: r'adminUserNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminUserNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AdminUserNotifier = AutoDisposeNotifier<AsyncValue<AdminUserState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
