import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category.dart';

/// Handles all Firestore read operations for the `/categories` collection
/// in the context of the admin dashboard.
///
/// Writes (create, update, deactivate, activate) go through Cloud Functions
/// and are handled separately via [CloudFunctionAdminDataSource].
class FirestoreAdminCategoryDataSource {
  FirestoreAdminCategoryDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  /// Returns a real-time stream of all categories from the `/categories`
  /// collection.
  ///
  /// Emits a new list whenever any document in the collection changes.
  /// Categories are ordered by name ascending for consistent display.
  Stream<List<Category>> watchAllCategories() {
    return _categoriesCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Fetches all categories once from the `/categories` collection.
  Future<List<Category>> getAllCategories() async {
    final snapshot = await _categoriesCollection.orderBy('name').get();
    return snapshot.docs
        .map((doc) => Category.fromMap(doc.id, doc.data()))
        .toList();
  }
}
