import '../../domain/entities/category.dart';
import '../../domain/repositories/i_admin_category_repository.dart';
import '../datasources/cloud_function_admin_data_source.dart';
import '../datasources/firestore_admin_category_data_source.dart';

/// Concrete implementation of [IAdminCategoryRepository].
///
/// Delegates read operations to [FirestoreAdminCategoryDataSource].
/// Writes go through [CloudFunctionAdminDataSource] via the
/// `adminManageCategory` Cloud Function.
class AdminCategoryRepository implements IAdminCategoryRepository {
  const AdminCategoryRepository(
    this._firestoreDataSource,
    this._cloudFunctionDataSource,
  );

  final FirestoreAdminCategoryDataSource _firestoreDataSource;
  final CloudFunctionAdminDataSource _cloudFunctionDataSource;

  @override
  Stream<List<Category>> watchAllCategories() =>
      _firestoreDataSource.watchAllCategories();

  @override
  Future<List<Category>> getAllCategories() =>
      _firestoreDataSource.getAllCategories();

  @override
  Future<String> createCategory(Map<String, dynamic> data) async {
    final result = await _cloudFunctionDataSource.manageCategory({
      'action': 'create',
      ...data,
    });
    return result['categoryId'] as String;
  }

  @override
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    await _cloudFunctionDataSource.manageCategory({
      'action': 'update',
      'categoryId': categoryId,
      ...data,
    });
  }

  @override
  Future<void> deactivateCategory(String categoryId) async {
    await _cloudFunctionDataSource.manageCategory({
      'action': 'deactivate',
      'categoryId': categoryId,
    });
  }

  @override
  Future<void> activateCategory(String categoryId) async {
    await _cloudFunctionDataSource.manageCategory({
      'action': 'activate',
      'categoryId': categoryId,
    });
  }
}
