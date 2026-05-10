import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/meal.dart';

/// Handles all Firestore read operations for the `/meals` collection
/// in the context of the admin dashboard.
///
/// Writes (create, update, delete) go through Cloud Functions and are
/// handled separately. Availability toggle is a direct Firestore write
/// because it is a simple field update that does not require server-side
/// business logic validation.
class FirestoreAdminMealDataSource {
  FirestoreAdminMealDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _mealsCollection =>
      _firestore.collection('meals');

  /// Returns a real-time stream of all meals from the `/meals` collection.
  ///
  /// Emits a new list whenever any document in the collection changes.
  /// Meals are ordered by name ascending for consistent display.
  Stream<List<Meal>> watchAllMeals() {
    return _mealsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meal.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Fetches all meals once from the `/meals` collection.
  Future<List<Meal>> getAllMeals() async {
    final snapshot = await _mealsCollection.orderBy('name').get();
    return snapshot.docs
        .map((doc) => Meal.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Updates the `isAvailable` field of the meal with [mealId].
  ///
  /// This is a direct Firestore write (not via Cloud Function) because
  /// availability toggle is a simple, low-risk field update.
  Future<void> toggleAvailability(
    String mealId, {
    required bool isAvailable,
  }) async {
    await _mealsCollection.doc(mealId).update({'isAvailable': isAvailable});
  }
}
