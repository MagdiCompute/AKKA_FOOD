// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mealDetailHash() => r'589484976d486640dd69edf6dbe9988cd3792afa';

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

/// Fetches a single meal by [mealId] from [IMealRepository.getMealById].
///
/// Returns `null` when no meal with the given id exists.
///
/// Copied from [mealDetail].
@ProviderFor(mealDetail)
const mealDetailProvider = MealDetailFamily();

/// Fetches a single meal by [mealId] from [IMealRepository.getMealById].
///
/// Returns `null` when no meal with the given id exists.
///
/// Copied from [mealDetail].
class MealDetailFamily extends Family<AsyncValue<Meal?>> {
  /// Fetches a single meal by [mealId] from [IMealRepository.getMealById].
  ///
  /// Returns `null` when no meal with the given id exists.
  ///
  /// Copied from [mealDetail].
  const MealDetailFamily();

  /// Fetches a single meal by [mealId] from [IMealRepository.getMealById].
  ///
  /// Returns `null` when no meal with the given id exists.
  ///
  /// Copied from [mealDetail].
  MealDetailProvider call(String mealId) {
    return MealDetailProvider(mealId);
  }

  @override
  MealDetailProvider getProviderOverride(
    covariant MealDetailProvider provider,
  ) {
    return call(provider.mealId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'mealDetailProvider';
}

/// Fetches a single meal by [mealId] from [IMealRepository.getMealById].
///
/// Returns `null` when no meal with the given id exists.
///
/// Copied from [mealDetail].
class MealDetailProvider extends AutoDisposeFutureProvider<Meal?> {
  /// Fetches a single meal by [mealId] from [IMealRepository.getMealById].
  ///
  /// Returns `null` when no meal with the given id exists.
  ///
  /// Copied from [mealDetail].
  MealDetailProvider(String mealId)
    : this._internal(
        (ref) => mealDetail(ref as MealDetailRef, mealId),
        from: mealDetailProvider,
        name: r'mealDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$mealDetailHash,
        dependencies: MealDetailFamily._dependencies,
        allTransitiveDependencies: MealDetailFamily._allTransitiveDependencies,
        mealId: mealId,
      );

  MealDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mealId,
  }) : super.internal();

  final String mealId;

  @override
  Override overrideWith(
    FutureOr<Meal?> Function(MealDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MealDetailProvider._internal(
        (ref) => create(ref as MealDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mealId: mealId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Meal?> createElement() {
    return _MealDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MealDetailProvider && other.mealId == mealId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mealId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MealDetailRef on AutoDisposeFutureProviderRef<Meal?> {
  /// The parameter `mealId` of this provider.
  String get mealId;
}

class _MealDetailProviderElement extends AutoDisposeFutureProviderElement<Meal?>
    with MealDetailRef {
  _MealDetailProviderElement(super.provider);

  @override
  String get mealId => (origin as MealDetailProvider).mealId;
}

String _$adminMealsHash() => r'7ac32d4b95dfeb3e6988338da37475633a00f937';

/// Fetches all meals (including unavailable) for the admin management screen.
///
/// Uses a large [pageSize] to load all meals in a single request.
///
/// Copied from [adminMeals].
@ProviderFor(adminMeals)
final adminMealsProvider = AutoDisposeFutureProvider<List<Meal>>.internal(
  adminMeals,
  name: r'adminMealsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminMealsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminMealsRef = AutoDisposeFutureProviderRef<List<Meal>>;
String _$mealRepositoryHash() => r'0049502c8f664440a8fcec797f82177037733498';

/// Provides the concrete [MealRepository] bound to [IMealRepository].
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [mealRepository].
@ProviderFor(mealRepository)
final mealRepositoryProvider = AutoDisposeProvider<IMealRepository>.internal(
  mealRepository,
  name: r'mealRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mealRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MealRepositoryRef = AutoDisposeProviderRef<IMealRepository>;
String _$catalogNotifierHash() => r'c11b689b3edced2b8f861cb04d2044a9a00d36ba';

/// Manages the full state of the meal catalog browsing surface.
///
/// Responsibilities:
/// - Fetching the initial page of meals from [IMealRepository].
/// - Appending subsequent pages (cursor-based pagination).
/// - Applying client-side filter + sort pipeline.
/// - Delegating full-text search to [IMealRepository.searchMeals].
///
/// State shape: [CatalogState].
///
/// Copied from [CatalogNotifier].
@ProviderFor(CatalogNotifier)
final catalogNotifierProvider =
    AutoDisposeAsyncNotifierProvider<CatalogNotifier, CatalogState>.internal(
      CatalogNotifier.new,
      name: r'catalogNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$catalogNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CatalogNotifier = AutoDisposeAsyncNotifier<CatalogState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
