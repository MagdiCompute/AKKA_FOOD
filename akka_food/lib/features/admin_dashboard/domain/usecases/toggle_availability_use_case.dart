import '../repositories/i_admin_meal_repository.dart';

/// Toggles the availability of a meal in Firestore.
///
/// Wraps [IAdminMealRepository.toggleAvailability] as a single-responsibility
/// use case following Clean Architecture conventions.
///
/// This is a direct Firestore write (not via Cloud Function) because
/// availability toggle is a simple, low-risk field update that does not
/// require server-side business logic validation.
class ToggleAvailabilityUseCase {
  const ToggleAvailabilityUseCase(this._repository);

  final IAdminMealRepository _repository;

  /// Executes the use case.
  ///
  /// Sets the `isAvailable` field of the meal identified by [mealId] to
  /// [isAvailable] in Firestore.
  Future<void> call(String mealId, {required bool isAvailable}) =>
      _repository.toggleAvailability(mealId, isAvailable: isAvailable);
}
