// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_category_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminCategoryRepositoryHash() =>
    r'1841d146abf91b55c9e3db05f7ae1c6b11f29272';

/// Provides the [IAdminCategoryRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
///
/// Copied from [adminCategoryRepository].
@ProviderFor(adminCategoryRepository)
final adminCategoryRepositoryProvider =
    AutoDisposeProvider<IAdminCategoryRepository>.internal(
      adminCategoryRepository,
      name: r'adminCategoryRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminCategoryRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminCategoryRepositoryRef =
    AutoDisposeProviderRef<IAdminCategoryRepository>;
String _$adminCategoryNotifierHash() =>
    r'6b31a6b4a97eba814907b5636b8bfec0f8765dfe';

/// Manages the state for [AdminCategoryListScreen].
///
/// Listens to the real-time Firestore stream of all categories and exposes
/// a search control.
///
/// Satisfies Requirement 3.1.
///
/// Copied from [AdminCategoryNotifier].
@ProviderFor(AdminCategoryNotifier)
final adminCategoryNotifierProvider =
    AutoDisposeNotifierProvider<
      AdminCategoryNotifier,
      AsyncValue<AdminCategoryState>
    >.internal(
      AdminCategoryNotifier.new,
      name: r'adminCategoryNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminCategoryNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AdminCategoryNotifier =
    AutoDisposeNotifier<AsyncValue<AdminCategoryState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
