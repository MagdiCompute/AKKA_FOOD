import 'package:algoliasearch/algoliasearch.dart';

import 'package:akka_food/features/meal_catalog/data/datasources/algolia_constants.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';

/// Thrown when the Algolia search service is unavailable or returns an error.
///
/// Callers should catch this exception and fall back to the Firestore prefix
/// search implemented in [FirestoreMealDataSource.searchMeals].
class AlgoliaUnavailableException implements Exception {
  const AlgoliaUnavailableException([this.message, this.cause]);

  final String? message;
  final Object? cause;

  @override
  String toString() {
    final base =
        'AlgoliaUnavailableException: ${message ?? 'Algolia search is unavailable'}';
    return cause != null ? '$base (cause: $cause)' : base;
  }
}

/// Data source that performs full-text meal search via Algolia.
///
/// Uses the official [algoliasearch] package (`SearchClient`).
/// Credentials are injected at build time via:
///   `--dart-define=ALGOLIA_APP_ID=...`
///   `--dart-define=ALGOLIA_SEARCH_API_KEY=...`
///
/// When credentials are not configured (empty strings), [isAvailable] returns
/// `false` and callers should fall back to Firestore prefix search.
///
/// On any runtime error during search, an [AlgoliaUnavailableException] is
/// thrown so the caller can transparently fall back to Firestore.
class AlgoliaSearchDataSource {
  /// Creates an [AlgoliaSearchDataSource].
  ///
  /// If [client] is not provided, a [SearchClient] is initialised internally
  /// using [AlgoliaConstants]. Inject a custom [SearchClient] in tests.
  AlgoliaSearchDataSource({SearchClient? client})
      : _client = client ??
            SearchClient(
              appId: AlgoliaConstants.algoliaAppId,
              apiKey: AlgoliaConstants.algoliaSearchApiKey,
            );

  final SearchClient _client;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns `true` when Algolia credentials are configured and the service
  /// can be used. Returns `false` when either the app ID or the search API key
  /// is an empty string (i.e. not injected via `--dart-define`).
  bool get isAvailable =>
      AlgoliaConstants.algoliaAppId.isNotEmpty &&
      AlgoliaConstants.algoliaSearchApiKey.isNotEmpty;

  /// Searches the Algolia `meals` index for [query].
  ///
  /// Optionally narrows results using [filter]:
  /// - [MealFilter.categoryIds] → `categoryId:X OR categoryId:Y`
  /// - [MealFilter.availableOnly] → `isAvailable:true`
  /// - [MealFilter.dietaryTags] → `dietaryTags:X AND dietaryTags:Y`
  /// - [MealFilter.minPrice] / [MealFilter.maxPrice] → numeric filter on `price`
  ///
  /// Throws [AlgoliaUnavailableException] on any error so the caller can fall
  /// back to Firestore prefix search.
  Future<List<Meal>> searchMeals(String query, {MealFilter? filter}) async {
    try {
      final filterString = _buildFilterString(filter);
      final numericFilters = _buildNumericFilters(filter);

      final searchParams = SearchParamsObject(
        query: query,
        filters: filterString.isNotEmpty ? filterString : null,
        numericFilters: numericFilters.isNotEmpty ? numericFilters : null,
      );

      final response = await _client.searchSingleIndex(
        indexName: AlgoliaConstants.mealsIndexName,
        searchParams: searchParams,
      );

      return response.hits.map(_hitToMeal).toList();
    } on AlgoliaUnavailableException {
      rethrow;
    } catch (e) {
      throw AlgoliaUnavailableException(
        'Search failed for query "$query"',
        e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Converts an Algolia [Hit] to a [Meal].
  ///
  /// [Hit] extends [DelegatingMap<String, dynamic>] so the indexed document
  /// fields are accessible via map access. The [Hit.objectID] is injected as
  /// `id` so [Meal.fromMap] can pick it up.
  Meal _hitToMeal(Hit hit) {
    // Hit extends DelegatingMap so we can spread it into a new map.
    final data = Map<String, dynamic>.from(hit);
    data['id'] = hit.objectID;
    return Meal.fromMap(data);
  }

  /// Builds the Algolia facet filter string from [MealFilter].
  ///
  /// Returns an empty string when no facet filters are active.
  ///
  /// Filter format:
  /// - Category IDs: `(categoryId:X OR categoryId:Y)` — OR semantics
  /// - Availability: `isAvailable:true`
  /// - Dietary tags: `(dietaryTags:X AND dietaryTags:Y)` — AND semantics
  String _buildFilterString(MealFilter? filter) {
    if (filter == null) return '';

    final parts = <String>[];

    // Category IDs — OR semantics: a meal matches if it belongs to any of the
    // selected categories.
    if (filter.categoryIds.isNotEmpty) {
      final categoryFilter =
          filter.categoryIds.map((id) => 'categoryId:$id').join(' OR ');
      parts.add('($categoryFilter)');
    }

    // Availability — only include meals that are currently available.
    if (filter.availableOnly) {
      parts.add('isAvailable:true');
    }

    // Dietary tags — AND semantics: a meal must carry all selected tags.
    if (filter.dietaryTags.isNotEmpty) {
      final tagFilter =
          filter.dietaryTags.map((tag) => 'dietaryTags:$tag').join(' AND ');
      parts.add('($tagFilter)');
    }

    return parts.join(' AND ');
  }

  /// Builds the Algolia numeric filter expressions from [MealFilter].
  ///
  /// Returns an empty list when no numeric filters are active.
  List<String> _buildNumericFilters(MealFilter? filter) {
    if (filter == null) return const [];

    final filters = <String>[];

    if (filter.minPrice != null) {
      filters.add('price >= ${filter.minPrice}');
    }
    if (filter.maxPrice != null) {
      filters.add('price <= ${filter.maxPrice}');
    }

    return filters;
  }
}
