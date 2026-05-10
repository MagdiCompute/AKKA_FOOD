import '../repositories/i_admin_meal_repository.dart';

/// Updates an existing meal via the `adminUpdateMeal` Cloud Function.
///
/// Wraps [IAdminMealRepository.updateMeal] as a single-responsibility
/// use case following Clean Architecture conventions.
///
/// All admin updates go through Cloud Functions (never direct Firestore
/// client writes) as required by the admin dashboard security design.
class UpdateMealUseCase {
  const UpdateMealUseCase(this._repository);

  final IAdminMealRepository _repository;

  /// Executes the use case.
  ///
  /// [mealId] identifies the meal to update; [data] contains the fields to
  /// update. Throws on error (e.g. permission denied, meal not found).
  Future<void> call(String mealId, Map<String, dynamic> data) =>
      _repository.updateMeal(mealId, data);
}
