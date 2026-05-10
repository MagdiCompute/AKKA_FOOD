import '../entities/category.dart';

/// Abstract repository interface for admin category operations.
///
/// Implementations live in the data layer and depend on Firebase.
/// The domain layer only depends on this interface.
abstract interface class IAdminCategoryRepository {
  /// Returns a real-time stream of all categories.
  ///
  /// The stream emits a new list whenever the `/categories` collection changes.
  Stream<List<Category>> watchAllCategories();

  /// Fetches all categories once (non-streaming).
  Future<List<Category>> getAllCategories();

  /// Creates a new category via the `adminManageCategory` Cloud Function.
  ///
  /// [data] must include at minimum `name`.
  /// Returns the new category's ID on success.
  /// Throws on error (e.g. permission denied, duplicate name).
  Future<String> createCategory(Map<String, dynamic> data);

  /// Updates an existing category via the `adminManageCategory` Cloud Function.
  ///
  /// [categoryId] identifies the category to update; [data] contains the
  /// fields to update. Throws on error (e.g. permission denied, not found).
  Future<void> updateCategory(String categoryId, Map<String, dynamic> data);

  /// Deactivates the category with [categoryId] and sets all its meals to
  /// unavailable via the `adminManageCategory` Cloud Function.
  ///
  /// Throws on error (e.g. permission denied, not found).
  Future<void> deactivateCategory(String categoryId);

  /// Activates the category with [categoryId] via the `adminManageCategory`
  /// Cloud Function.
  ///
  /// Throws on error (e.g. permission denied, not found).
  Future<void> activateCategory(String categoryId);
}
