import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category.dart';
import '../../domain/repositories/i_admin_category_repository.dart';
import '../datasources/cloud_function_admin_data_source.dart';
import '../datasources/firestore_admin_category_data_source.dart';

/// Concrete implementation of [IAdminCategoryRepository].
///
/// Delegates read operations to [FirestoreAdminCategoryDataSource].
/// Writes go directly to Firestore (Cloud Functions not yet deployed).
class AdminCategoryRepository implements IAdminCategoryRepository {
  const AdminCategoryRepository(
    this._firestoreDataSource,
    this._cloudFunctionDataSource,
  );

  final FirestoreAdminCategoryDataSource _firestoreDataSource;
  final CloudFunctionAdminDataSource _cloudFunctionDataSource;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Stream<List<Category>> watchAllCategories() =>
      _firestoreDataSource.watchAllCategories();

  @override
  Future<List<Category>> getAllCategories() =>
      _firestoreDataSource.getAllCategories();

  @override
  Future<String> createCategory(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('categories').add({
      'name': data['name'],
      'imageUrl': data['imageUrl'],
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('categories').doc(categoryId).update(data);
  }

  @override
  Future<void> deactivateCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).update({
      'isActive': false,
    });
  }

  @override
  Future<void> activateCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).update({
      'isActive': true,
    });
  }
}
