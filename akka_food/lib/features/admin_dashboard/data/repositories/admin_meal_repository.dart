import '../../domain/entities/meal.dart';
import '../../domain/repositories/i_admin_meal_repository.dart';
import '../datasources/cloud_function_admin_data_source.dart';
import '../datasources/firestore_admin_meal_data_source.dart';

/// Concrete implementation of [IAdminMealRepository].
///
/// Delegates read operations to [FirestoreAdminMealDataSource] and
/// write operations (via Cloud Functions) to [CloudFunctionAdminDataSource].
class AdminMealRepository implements IAdminMealRepository {
  const AdminMealRepository(
    this._firestoreDataSource,
    this._cloudFunctionDataSource,
  );

  final FirestoreAdminMealDataSource _firestoreDataSource;
  final CloudFunctionAdminDataSource _cloudFunctionDataSource;

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
  Future<String> createMeal(Map<String, dynamic> data) =>
      _cloudFunctionDataSource.createMeal(data);

  @override
  Future<void> updateMeal(String mealId, Map<String, dynamic> data) =>
      _cloudFunctionDataSource.updateMeal(mealId, data);

  @override
  Future<void> deleteMeal(String mealId) =>
      _cloudFunctionDataSource.deleteMeal(mealId);
}
