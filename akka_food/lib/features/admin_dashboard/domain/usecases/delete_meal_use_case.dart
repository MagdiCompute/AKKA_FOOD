import '../repositories/i_admin_meal_repository.dart';

/// Deletes a meal via the `adminDeleteMeal` Cloud Function.
///
/// Wraps [IAdminMealRepository.deleteMeal] as a single-responsibility
/// use case following Clean Architecture conventions.
///
/// All admin deletes go through Cloud Functions (never direct Firestore
/// client writes) as required by the admin dashboard security design.
class DeleteMealUseCase {
  const DeleteMealUseCase(this._repository);

  final IAdminMealRepository _repository;

  /// Executes the use case.
  ///
  /// Deletes the meal identified by [mealId] via the Cloud Function.
  /// Throws on error (e.g. permission denied, meal not found).
  Future<void> call(String mealId) => _repository.deleteMeal(mealId);
}
