import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/category.dart';

/// Firestore data source for meal categories.
///
/// Handles all direct Firestore interactions for the `/categories` collection.
/// Firebase imports are intentionally confined to this data-layer class.
class FirestoreCategoryDataSource {
  FirestoreCategoryDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'categories';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all categories where [Category.isActive] is `true`, ordered by
  /// [Category.name] ascending.
  Future<List<Category>> getActiveCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return Category.fromMap({...data, 'id': doc.id});
      }).toList();

      // Sort client-side to avoid composite index requirement
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    } catch (e) {
      // Fallback: fetch all categories without filter
      try {
        final snapshot = await _firestore.collection(_collection).get();
        final categories = snapshot.docs.map((doc) {
          final data = doc.data();
          return Category.fromMap({...data, 'id': doc.id});
        }).toList();
        categories.sort((a, b) => a.name.compareTo(b.name));
        return categories;
      } catch (_) {
        return [];
      }
    }
  }

  /// Returns the [Category] with the given [id], or `null` if not found.
  Future<Category?> getCategoryById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();

    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    return Category.fromMap({...data, 'id': doc.id});
  }

  /// Writes a new [category] document to `/categories/{category.id}`.
  Future<void> createCategory(Category category) async {
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .set(category.toMap());
  }

  /// Overwrites the existing category document at `/categories/{category.id}`
  /// with the data from [category].
  Future<void> updateCategory(Category category) async {
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .update(category.toMap());
  }

  /// Sets `isActive: false` on the category document at `/categories/{id}`.
  ///
  /// Note: a Cloud Function is responsible for also setting `isAvailable=false`
  /// on all meals belonging to this category.
  Future<void> deactivateCategory(String id) async {
    await _firestore
        .collection(_collection)
        .doc(id)
        .update({'isActive': false});
  }
}
