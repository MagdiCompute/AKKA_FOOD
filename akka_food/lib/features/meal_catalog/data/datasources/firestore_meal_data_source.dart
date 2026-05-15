import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';

/// Firestore data source for the meal catalog.
///
/// Handles all direct Firestore interactions for the `/meals` collection.
/// Firebase imports are intentionally confined to this data-layer class.
///
/// ## Composite Index Note
/// Several filter + sort combinations require composite indexes in Firestore.
/// Ensure the following indexes are declared in `firestore.indexes.json`:
///   - (isAvailable ASC, createdAt DESC)
///   - (isAvailable ASC, price ASC)
///   - (isAvailable ASC, price DESC)
///   - (isAvailable ASC, popularityScore DESC)
///   - (categoryId ASC, createdAt DESC)
///   - (categoryId ASC, price ASC)
///   - (categoryId ASC, price DESC)
///   - (categoryId ASC, popularityScore DESC)
///   - (dietaryTags ARRAY, createdAt DESC)
///   - (dietaryTags ARRAY, price ASC)
///   - (dietaryTags ARRAY, price DESC)
///   - (dietaryTags ARRAY, popularityScore DESC)
///   - (isFeatured ASC, featuredOrder ASC)
/// Firestore will also prompt you to create missing indexes via a link in the
/// error message when a query is first executed without the required index.
class FirestoreMealDataSource {
  FirestoreMealDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'meals';
  static const int _defaultPageSize = 20;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [Meal]s from Firestore.
  ///
  /// - [filter] narrows results by category, price range, availability, and
  ///   dietary tags. Pass `null` to apply no filtering.
  /// - [sort] controls the ordering. Defaults to `createdAt` descending.
  /// - [pageSize] controls how many documents are returned (default 20).
  /// - [startAfterDocument] is the Firestore cursor from the last document of
  ///   the previous page; pass `null` to fetch the first page.
  Future<List<Meal>> getMeals({
    MealFilter? filter,
    MealSortOption? sort,
    int pageSize = _defaultPageSize,
    DocumentSnapshot? startAfterDocument,
  }) async {
    Query<Map<String, dynamic>> query = _buildQuery(
      filter: filter,
      sort: sort,
    );

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    query = query.limit(pageSize);

    final snapshot = await query.get();
    return _snapshotToMeals(snapshot);
  }

  /// Returns the [Meal] with the given [id], or `null` if not found.
  Future<Meal?> getMealById(String id) async {
    final doc =
        await _firestore.collection(_collection).doc(id).get();

    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    return Meal.fromMap({...data, 'id': doc.id});
  }

  /// Returns all featured meals ordered by [Meal.featuredOrder] ascending.
  ///
  /// Queries `/meals` where `isFeatured == true`.
  /// Requires a composite index on `(isFeatured ASC, featuredOrder ASC)`.
  Future<List<Meal>> getFeaturedMeals() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isFeatured', isEqualTo: true)
        .orderBy('featuredOrder', descending: false)
        .get();

    return _snapshotToMeals(snapshot);
  }

  /// Returns the last [DocumentSnapshot] for the given query parameters.
  ///
  /// Useful for initialising the cursor when the caller needs to know the
  /// last document without fetching the full page again.
  Future<DocumentSnapshot?> getLastDocument({
    MealFilter? filter,
    MealSortOption? sort,
    int pageSize = _defaultPageSize,
  }) async {
    Query<Map<String, dynamic>> query = _buildQuery(
      filter: filter,
      sort: sort,
    );

    query = query.limit(pageSize);

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.last;
  }

  /// Searches meals whose [Meal.name] starts with [query] using a Firestore
  /// prefix range filter.
  ///
  /// Fetches all meals and filters client-side for case-insensitive
  /// "contains" matching. This provides better search results than the
  /// Firestore prefix approach (which only matches from the start).
  Future<List<Meal>> searchMeals(String query) async {
    final lowerQuery = query.toLowerCase();

    // Fetch all meals and filter client-side for "contains" matching
    final snapshot = await _firestore
        .collection(_collection)
        .get();

    final allMeals = _snapshotToMeals(snapshot);
    return allMeals
        .where((meal) => meal.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Writes a new [meal] document to `/meals/{meal.id}`.
  Future<void> createMeal(Meal meal) async {
    await _firestore
        .collection(_collection)
        .doc(meal.id)
        .set(meal.toMap());
  }

  /// Overwrites the existing meal document at `/meals/{meal.id}` with the
  /// data from [meal].
  Future<void> updateMeal(Meal meal) async {
    await _firestore
        .collection(_collection)
        .doc(meal.id)
        .update(meal.toMap());
  }

  /// Deletes the meal document at `/meals/{id}`.
  Future<void> deleteMeal(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds a Firestore [Query] with optional filters and sort applied.
  Query<Map<String, dynamic>> _buildQuery({
    MealFilter? filter,
    MealSortOption? sort,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(_collection);

    // ---- Filters -----------------------------------------------------------

    if (filter != null) {
      // Category filter — Firestore whereIn supports up to 10 values.
      if (filter.categoryIds.isNotEmpty) {
        final ids = filter.categoryIds.take(10).toList();
        query = query.where('categoryId', whereIn: ids);
      }

      // Availability filter.
      if (filter.availableOnly) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      // Price range filters.
      if (filter.minPrice != null) {
        query = query.where(
          'price',
          isGreaterThanOrEqualTo: filter.minPrice,
        );
      }
      if (filter.maxPrice != null) {
        query = query.where(
          'price',
          isLessThanOrEqualTo: filter.maxPrice,
        );
      }

      // Dietary tags filter.
      // Firestore `arrayContainsAny` supports up to 10 values but matches
      // documents containing ANY of the provided tags (OR semantics).
      // For AND semantics across multiple tags, additional client-side
      // filtering is required after fetching results.
      if (filter.dietaryTags.isNotEmpty) {
        // Use the first tag with arrayContains for a single-tag exact match,
        // or arrayContainsAny for multi-tag OR matching (Firestore limitation).
        if (filter.dietaryTags.length == 1) {
          query = query.where(
            'dietaryTags',
            arrayContains: filter.dietaryTags.first,
          );
        } else {
          final tags = filter.dietaryTags.take(10).toList();
          query = query.where('dietaryTags', arrayContainsAny: tags);
        }
      }
    }

    // ---- Sort --------------------------------------------------------------

    switch (sort) {
      case MealSortOption.priceAsc:
        query = query.orderBy('price', descending: false);
      case MealSortOption.priceDesc:
        query = query.orderBy('price', descending: true);
      case MealSortOption.popularityDesc:
        query = query.orderBy('popularityScore', descending: true);
      case MealSortOption.newestFirst:
        query = query.orderBy('createdAt', descending: true);
      case null:
        // Default ordering: newest first.
        query = query.orderBy('createdAt', descending: true);
    }

    return query;
  }

  /// Converts a Firestore [QuerySnapshot] to a list of [Meal]s.
  List<Meal> _snapshotToMeals(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Inject the Firestore document ID into the map so Meal.fromMap can
      // pick it up via the 'id' key.
      return Meal.fromMap({...data, 'id': doc.id});
    }).toList();
  }
}
