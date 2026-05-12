import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/meal.dart';
import '../../domain/repositories/i_admin_meal_repository.dart';
import '../datasources/cloud_function_admin_data_source.dart';
import '../datasources/firestore_admin_meal_data_source.dart';

/// Concrete implementation of [IAdminMealRepository].
///
/// Delegates read operations to [FirestoreAdminMealDataSource].
/// Write operations go directly to Firestore (Cloud Functions not yet deployed).
class AdminMealRepository implements IAdminMealRepository {
  const AdminMealRepository(
    this._firestoreDataSource,
    this._cloudFunctionDataSource,
  );

  final FirestoreAdminMealDataSource _firestoreDataSource;
  final CloudFunctionAdminDataSource _cloudFunctionDataSource;

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Stream<List<Meal>> watchAllMeals() => _firestoreDataSource.watchAllMeals();

  @override
  Future<List<Meal>> getAllMeals() => _firestoreDataSource.getAllMeals();

  @override
  Future<void> toggleAvailability(
    String mealId, {
    required bool isAvailable,
  }) =>
      _firestoreDataSource.toggleAvailability(mealId, isAvailable: isAvailable);

  @override
  Future<String> createMeal(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('meals').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Future<void> updateMeal(String mealId, Map<String, dynamic> data) async {
    await _firestore.collection('meals').doc(mealId).update(data);
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    await _firestore.collection('meals').doc(mealId).delete();
  }
}
