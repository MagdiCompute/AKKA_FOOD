import '../repositories/i_admin_category_repository.dart';

/// Creates a new category via the `adminManageCategory` Cloud Function.
///
/// Wraps [IAdminCategoryRepository.createCategory] as a single-responsibility
/// use case following Clean Architecture conventions.
///
/// Satisfies Requirements 3.2 and 3.4.
class CreateCategoryUseCase {
  const CreateCategoryUseCase(this._repository);

  final IAdminCategoryRepository _repository;

  /// Executes the use case.
  ///
  /// [data] must include at minimum `name`.
  /// Returns the new category's ID on success.
  /// Throws on error (e.g. permission denied, duplicate name).
  Future<String> call(Map<String, dynamic> data) =>
      _repository.createCategory(data);
}
