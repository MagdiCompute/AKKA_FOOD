import '../entities/meal.dart';
import '../repositories/i_admin_meal_repository.dart';

/// Returns a real-time stream of all meals for the admin dashboard.
///
/// Wraps [IAdminMealRepository.watchAllMeals] as a single-responsibility
/// use case following Clean Architecture conventions.
class GetAdminMealsUseCase {
  const GetAdminMealsUseCase(this._repository);

  final IAdminMealRepository _repository;

  /// Executes the use case.
  ///
  /// Returns a [Stream] that emits the full list of meals (available and
  /// unavailable) whenever the Firestore `/meals` collection changes.
  Stream<List<Meal>> call() => _repository.watchAllMeals();
}
