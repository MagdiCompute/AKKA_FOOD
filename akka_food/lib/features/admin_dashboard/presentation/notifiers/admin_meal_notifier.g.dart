// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_meal_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminMealRepositoryHash() =>
    r'55dbbdf2a0608dc4e0c005af5938272aeae757ab';

/// Provides the [IAdminMealRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
///
/// Copied from [adminMealRepository].
@ProviderFor(adminMealRepository)
final adminMealRepositoryProvider =
    AutoDisposeProvider<IAdminMealRepository>.internal(
      adminMealRepository,
      name: r'adminMealRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminMealRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminMealRepositoryRef = AutoDisposeProviderRef<IAdminMealRepository>;
String _$adminMealNotifierHash() => r'cf4b0c0a18fc4601acc42eea334e47f21c1c897a';

/// Manages the state for [AdminMealListScreen].
///
/// Listens to the real-time Firestore stream of all meals and exposes
/// search/filter controls.
///
/// Copied from [AdminMealNotifier].
@ProviderFor(AdminMealNotifier)
final adminMealNotifierProvider =
    AutoDisposeNotifierProvider<
      AdminMealNotifier,
      AsyncValue<AdminMealState>
    >.internal(
      AdminMealNotifier.new,
      name: r'adminMealNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminMealNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AdminMealNotifier = AutoDisposeNotifier<AsyncValue<AdminMealState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
