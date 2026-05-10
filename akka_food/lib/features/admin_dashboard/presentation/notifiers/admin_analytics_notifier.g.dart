// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_analytics_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminAnalyticsRepositoryHash() =>
    r'3e2f0e7aafb0d5e87e9e2dd6c22a3fcf59c71cd3';

/// Provides the [IAdminAnalyticsRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
///
/// Copied from [adminAnalyticsRepository].
@ProviderFor(adminAnalyticsRepository)
final adminAnalyticsRepositoryProvider =
    AutoDisposeProvider<IAdminAnalyticsRepository>.internal(
      adminAnalyticsRepository,
      name: r'adminAnalyticsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminAnalyticsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminAnalyticsRepositoryRef =
    AutoDisposeProviderRef<IAdminAnalyticsRepository>;
String _$adminAnalyticsNotifierHash() =>
    r'155f5440a5bbc4406771ccdebe02c75b60b8da0a';

/// Manages the state for [AdminAnalyticsScreen].
///
/// Listens to the real-time Firestore stream of `/analytics/summary` and
/// exposes period switching (today | week | month).
///
/// Satisfies Requirements 5.1, 5.2, 5.3, and 5.4.
///
/// Copied from [AdminAnalyticsNotifier].
@ProviderFor(AdminAnalyticsNotifier)
final adminAnalyticsNotifierProvider =
    AutoDisposeNotifierProvider<
      AdminAnalyticsNotifier,
      AsyncValue<AdminAnalyticsState>
    >.internal(
      AdminAnalyticsNotifier.new,
      name: r'adminAnalyticsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminAnalyticsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AdminAnalyticsNotifier =
    AutoDisposeNotifier<AsyncValue<AdminAnalyticsState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
