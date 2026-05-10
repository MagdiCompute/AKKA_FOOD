import '../entities/meal.dart';

/// Abstract repository interface for admin meal operations.
///
/// Implementations live in the data layer and depend on Firebase.
/// The domain layer only depends on this interface.
abstract interface class IAdminMealRepository {
  /// Returns a stream of all meals (available and unavailable).
  ///
  /// The stream emits a new list whenever the `/meals` collection changes.
  Stream<List<Meal>> watchAllMeals();

  /// Fetches all meals once (non-streaming).
  Future<List<Meal>> getAllMeals();

  /// Toggles the availability of the meal with [mealId].
  ///
  /// Sets `isAvailable` to [isAvailable] in Firestore.
  Future<void> toggleAvailability(String mealId, {required bool isAvailable});

  /// Creates a new meal via the `adminCreateMeal` Cloud Function.
  ///
  /// [data] must include at minimum `name`, `price`, and `categoryId`.
  /// Returns the new meal's ID on success.
  /// Throws on error (e.g. permission denied, invalid data).
  Future<String> createMeal(Map<String, dynamic> data);

  /// Updates an existing meal via the `adminUpdateMeal` Cloud Function.
  ///
  /// [mealId] identifies the meal to update; [data] contains the fields to
  /// update. Throws on error (e.g. permission denied, meal not found).
  Future<void> updateMeal(String mealId, Map<String, dynamic> data);

  /// Deletes the meal with [mealId] via the `adminDeleteMeal` Cloud Function.
  ///
  /// Throws on error (e.g. permission denied, meal not found).
  Future<void> deleteMeal(String mealId);
}
