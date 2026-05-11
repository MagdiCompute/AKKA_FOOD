// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recommendationRepositoryHash() =>
    r'c15b41ed34da0e65e860eb051873149fb7c6406b';

/// Provides the concrete [RecommendationRepositoryImpl] bound to
/// [IRecommendationRepository].
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [recommendationRepository].
@ProviderFor(recommendationRepository)
final recommendationRepositoryProvider =
    AutoDisposeProvider<IRecommendationRepository>.internal(
      recommendationRepository,
      name: r'recommendationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recommendationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecommendationRepositoryRef =
    AutoDisposeProviderRef<IRecommendationRepository>;
String _$catalogCacheHash() => r'2f3e4d0b19597c8724f39328499f320c8e11c53a';

/// Provides the [HiveCatalogCache] instance for resolving meal IDs.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [catalogCache].
@ProviderFor(catalogCache)
final catalogCacheProvider = AutoDisposeProvider<HiveCatalogCache>.internal(
  catalogCache,
  name: r'catalogCacheProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$catalogCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CatalogCacheRef = AutoDisposeProviderRef<HiveCatalogCache>;
String _$recommendationNotifierHash() =>
    r'a32039214f6630529c4d03b37c7831b2081d011e';

/// Manages the recommendation state for the "Recommended for You" section.
///
/// Responsibilities:
/// - Fetching recommendations via [IRecommendationRepository].
/// - Resolving meal IDs to full [Meal] objects from the local Hive cache.
/// - Filtering out unavailable meals client-side.
/// - Limiting results to a maximum of 10 meals.
/// - Exposing [isPersonalized] for the UI header.
///
/// On error, emits an empty list silently (Requirement 4, Criteria 4).
///
/// Copied from [RecommendationNotifier].
@ProviderFor(RecommendationNotifier)
final recommendationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      RecommendationNotifier,
      List<Meal>
    >.internal(
      RecommendationNotifier.new,
      name: r'recommendationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recommendationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecommendationNotifier = AutoDisposeAsyncNotifier<List<Meal>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
