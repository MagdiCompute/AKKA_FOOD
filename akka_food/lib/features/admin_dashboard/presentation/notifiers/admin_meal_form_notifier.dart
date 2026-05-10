import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/meal.dart';
import '../../domain/usecases/create_meal_use_case.dart';
import '../../domain/usecases/delete_meal_use_case.dart';
import '../../domain/usecases/update_meal_use_case.dart';
import 'admin_meal_notifier.dart';

part 'admin_meal_form_notifier.g.dart';

// ---------------------------------------------------------------------------
// Form state
// ---------------------------------------------------------------------------

/// Holds all editable fields for the meal create/edit form.
class AdminMealFormState {
  const AdminMealFormState({
    this.mealId,
    this.name = '',
    this.description = '',
    this.price = '',
    this.category = '',
    this.imageUrls = const [],
    this.dietaryTags = const [],
    this.calories = '',
    this.protein = '',
    this.carbs = '',
    this.fat = '',
    this.isAvailable = true,
    this.isFeatured = false,
    this.featuredOrder = '',
    this.isSaving = false,
    this.isLoading = false,
    this.errorMessage,
    this.uploadProgress,
  });

  /// Non-null when editing an existing meal.
  final String? mealId;

  // ── Core fields ──────────────────────────────────────────────────────────
  final String name;
  final String description;

  /// Price as a string (user input); parsed to double on save.
  final String price;
  final String category;

  /// Image URLs already persisted in Firebase Storage.
  final List<String> imageUrls;

  // ── Dietary tags ─────────────────────────────────────────────────────────
  final List<String> dietaryTags;

  // ── Nutritional info ─────────────────────────────────────────────────────
  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  // ── Toggles ──────────────────────────────────────────────────────────────
  final bool isAvailable;
  final bool isFeatured;

  /// Featured order as a string (user input); parsed to int on save.
  final String featuredOrder;

  // ── UI state ─────────────────────────────────────────────────────────────
  final bool isSaving;
  final bool isLoading;
  final String? errorMessage;

  /// Upload progress in the range [0.0, 1.0], or `null` when not uploading.
  final double? uploadProgress;

  /// Returns `true` when the form is in edit mode.
  bool get isEditMode => mealId != null;

  AdminMealFormState copyWith({
    String? mealId,
    String? name,
    String? description,
    String? price,
    String? category,
    List<String>? imageUrls,
    List<String>? dietaryTags,
    String? calories,
    String? protein,
    String? carbs,
    String? fat,
    bool? isAvailable,
    bool? isFeatured,
    String? featuredOrder,
    bool? isSaving,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    double? uploadProgress,
    bool clearUploadProgress = false,
  }) {
    return AdminMealFormState(
      mealId: mealId ?? this.mealId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredOrder: featuredOrder ?? this.featuredOrder,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadProgress: clearUploadProgress
          ? null
          : (uploadProgress ?? this.uploadProgress),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages form state for [AdminMealFormScreen].
///
/// Handles both create mode (mealId == null) and edit mode (mealId != null).
/// Cloud Function calls are stubbed and will be wired in tasks 3.5 and 3.6.
@riverpod
class AdminMealFormNotifier extends _$AdminMealFormNotifier {
  @override
  AdminMealFormState build() {
    return const AdminMealFormState();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Initialises the form for create mode (no pre-population).
  void initCreate() {
    state = const AdminMealFormState();
  }

  /// Loads an existing meal into the form for edit mode.
  ///
  /// Reads from the already-loaded meal list in [adminMealNotifierProvider]
  /// to avoid an extra Firestore round-trip.
  Future<void> loadMeal(String mealId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Try to find the meal in the already-loaded list first.
      final mealListState =
          ref.read(adminMealNotifierProvider).valueOrNull;
      Meal? meal = mealListState?.allMeals
          .where((m) => m.id == mealId)
          .firstOrNull;

      if (meal == null) {
        // Fallback: fetch directly from the repository.
        final repository = ref.read(adminMealRepositoryProvider);
        final meals = await repository.getAllMeals();
        meal = meals.where((m) => m.id == mealId).firstOrNull;
      }

      if (meal == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Meal not found.',
        );
        return;
      }

      state = AdminMealFormState(
        mealId: mealId,
        name: meal.name,
        description: meal.description,
        price: meal.price == 0 ? '' : meal.price.toStringAsFixed(0),
        category: meal.category,
        imageUrls: List<String>.from(meal.imageUrls),
        isAvailable: meal.isAvailable,
        isFeatured: meal.isFeatured,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load meal: $e',
      );
    }
  }

  // ── Field setters ─────────────────────────────────────────────────────────

  void setName(String value) => state = state.copyWith(name: value);
  void setDescription(String value) =>
      state = state.copyWith(description: value);
  void setPrice(String value) => state = state.copyWith(price: value);
  void setCategory(String? value) =>
      state = state.copyWith(category: value ?? '');
  void setCalories(String value) => state = state.copyWith(calories: value);
  void setProtein(String value) => state = state.copyWith(protein: value);
  void setCarbs(String value) => state = state.copyWith(carbs: value);
  void setFat(String value) => state = state.copyWith(fat: value);
  void setIsAvailable(bool value) =>
      state = state.copyWith(isAvailable: value);
  void setIsFeatured(bool value) => state = state.copyWith(isFeatured: value);
  void setFeaturedOrder(String value) =>
      state = state.copyWith(featuredOrder: value);

  /// Toggles a dietary tag on/off.
  void toggleDietaryTag(String tag) {
    final current = List<String>.from(state.dietaryTags);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    state = state.copyWith(dietaryTags: current);
  }

  // ── Image URL management ──────────────────────────────────────────────────

  /// Adds [url] to the [imageUrls] list (max 5).
  void addImageUrl(String url) {
    if (state.imageUrls.length >= 5) return;
    state = state.copyWith(
      imageUrls: [...state.imageUrls, url],
    );
  }

  /// Removes [url] from the [imageUrls] list.
  void removeImageUrl(String url) {
    state = state.copyWith(
      imageUrls: state.imageUrls.where((u) => u != url).toList(),
    );
  }

  /// Updates the current upload progress (0.0–1.0).
  ///
  /// Pass `null` to clear the progress indicator.
  void setUploadProgress(double? progress) {
    if (progress == null) {
      state = state.copyWith(clearUploadProgress: true);
    } else {
      state = state.copyWith(uploadProgress: progress);
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  /// Returns an error message if the form is invalid, or `null` if valid.
  String? validate() {
    if (state.name.trim().isEmpty) return 'Name is required.';
    if (state.price.trim().isEmpty) return 'Price is required.';
    final parsedPrice = double.tryParse(state.price.trim());
    if (parsedPrice == null || parsedPrice < 0) {
      return 'Price must be a valid non-negative number.';
    }
    if (state.category.trim().isEmpty) return 'Category is required.';
    if (state.isFeatured && state.featuredOrder.trim().isNotEmpty) {
      final parsedOrder = int.tryParse(state.featuredOrder.trim());
      if (parsedOrder == null || parsedOrder < 0) {
        return 'Featured order must be a non-negative integer.';
      }
    }
    return null;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Validates the form and saves the meal.
  ///
  /// Returns `true` on success, `false` on validation failure or error.
  /// Calls `adminCreateMeal` in create mode or `adminUpdateMeal` in edit mode.
  Future<bool> save() async {
    final validationError = validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repository = ref.read(adminMealRepositoryProvider);

      // Build the nutritional info map from individual fields.
      final nutritionalInfo = <String, dynamic>{};
      final calories = int.tryParse(state.calories.trim());
      final protein = double.tryParse(state.protein.trim());
      final carbs = double.tryParse(state.carbs.trim());
      final fat = double.tryParse(state.fat.trim());
      if (calories != null) nutritionalInfo['calories'] = calories;
      if (protein != null) nutritionalInfo['protein'] = protein;
      if (carbs != null) nutritionalInfo['carbs'] = carbs;
      if (fat != null) nutritionalInfo['fat'] = fat;

      // Build the data map to send to the Cloud Function.
      final data = <String, dynamic>{
        'name': state.name.trim(),
        'description': state.description.trim(),
        'price': double.parse(state.price.trim()),
        'categoryId': state.category.trim(),
        'imageUrls': state.imageUrls,
        'dietaryTags': state.dietaryTags,
        if (nutritionalInfo.isNotEmpty) 'nutritionalInfo': nutritionalInfo,
        'isAvailable': state.isAvailable,
        'isFeatured': state.isFeatured,
        if (state.isFeatured && state.featuredOrder.trim().isNotEmpty)
          'featuredOrder': int.parse(state.featuredOrder.trim()),
      };

      if (state.isEditMode) {
        final useCase = UpdateMealUseCase(repository);
        await useCase(state.mealId!, data);
      } else {
        final useCase = CreateMealUseCase(repository);
        await useCase(data);
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save meal: $e',
      );
      return false;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Deletes the current meal via the `adminDeleteMeal` Cloud Function.
  ///
  /// Returns `true` on success, `false` on error.
  Future<bool> delete() async {
    if (!state.isEditMode) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repository = ref.read(adminMealRepositoryProvider);
      final useCase = DeleteMealUseCase(repository);
      await useCase(state.mealId!);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to delete meal: $e',
      );
      return false;
    }
  }

  /// Clears any current error message.
  void clearError() => state = state.copyWith(clearError: true);
}
