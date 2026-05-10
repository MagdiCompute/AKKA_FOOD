import '../entities/category.dart';
import '../repositories/i_admin_category_repository.dart';

/// Returns a real-time stream of all categories for the admin dashboard.
///
/// Wraps [IAdminCategoryRepository.watchAllCategories] as a
/// single-responsibility use case following Clean Architecture conventions.
class GetAdminCategoriesUseCase {
  const GetAdminCategoriesUseCase(this._repository);

  final IAdminCategoryRepository _repository;

  /// Executes the use case.
  ///
  /// Returns a [Stream] that emits the full list of categories (active and
  /// inactive) whenever the Firestore `/categories` collection changes.
  Stream<List<Category>> call() => _repository.watchAllCategories();
}
