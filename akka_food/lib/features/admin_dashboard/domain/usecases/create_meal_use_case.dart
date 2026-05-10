import '../repositories/i_admin_meal_repository.dart';

/// Creates a new meal via the `adminCreateMeal` Cloud Function.
///
/// Wraps [IAdminMealRepository.createMeal] as a single-responsibility
/// use case following Clean Architecture conventions.
///
/// All admin creates go through Cloud Functions (never direct Firestore
/// client writes) as required by the admin dashboard security design.
class CreateMealUseCase {
  const CreateMealUseCase(this._repository);

  final IAdminMealRepository _repository;

  /// Executes the use case.
  ///
  /// [data] must include at minimum `name`, `price`, and `categoryId`.
  /// Returns the new meal's ID on success.
  /// Throws on error (e.g. permission denied, invalid data).
  Future<String> call(Map<String, dynamic> data) =>
      _repository.createMeal(data);
}
