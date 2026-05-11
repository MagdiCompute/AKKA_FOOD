import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';

/// Dedicated Firestore data source for featured meals.
///
/// Intentionally separate from [FirestoreMealDataSource] to keep concerns
/// isolated — featured meals have their own caching bucket (`featured_cache`).
///
/// Firebase imports are intentionally confined to this data-layer class.
///
/// ## Composite Index Note
/// This query requires a composite index on `(isFeatured ASC, featuredOrder ASC)`.
/// Firestore will prompt you to create the missing index via a link in the
/// error message when the query is first executed without the required index.
class FirestoreFeaturedDataSource {
  FirestoreFeaturedDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'meals';

  /// Returns all featured meals ordered by [Meal.featuredOrder] ascending.
  ///
  /// Queries `/meals` where `isFeatured == true`, ordered by `featuredOrder`
  /// ascending. Deserializes each document using [Meal.fromMap].
  Future<List<Meal>> getFeaturedMeals() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isFeatured', isEqualTo: true)
        .orderBy('featuredOrder', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Meal.fromMap({...data, 'id': doc.id});
    }).toList();
  }
}
