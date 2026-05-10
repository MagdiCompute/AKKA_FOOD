import '../repositories/i_admin_category_repository.dart';

/// Updates an existing category via the `adminManageCategory` Cloud Function.
///
/// Wraps [IAdminCategoryRepository.updateCategory] as a single-responsibility
/// use case following Clean Architecture conventions.
class UpdateCategoryUseCase {
  const UpdateCategoryUseCase(this._repository);

  final IAdminCategoryRepository _repository;

  /// Executes the use case.
  ///
  /// [categoryId] identifies the category to update; [data] contains the
  /// fields to update. Throws on error (e.g. permission denied, not found).
  Future<void> call(String categoryId, Map<String, dynamic> data) =>
      _repository.updateCategory(categoryId, data);
}
