import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/create_category_use_case.dart';
import '../../domain/usecases/update_category_use_case.dart';
import 'admin_category_notifier.dart';

part 'admin_category_form_notifier.g.dart';

// ---------------------------------------------------------------------------
// Form state
// ---------------------------------------------------------------------------

/// Holds all editable fields for the category create/edit form.
class AdminCategoryFormState {
  const AdminCategoryFormState({
    this.categoryId,
    this.name = '',
    this.imageUrl,
    this.isActive = true,
    this.isSaving = false,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Non-null when editing an existing category.
  final String? categoryId;

  // ── Core fields ──────────────────────────────────────────────────────────
  final String name;

  /// URL of the category image stored in Firebase Storage, or `null`.
  final String? imageUrl;

  /// Whether the category is active (visible to users).
  final bool isActive;

  // ── UI state ─────────────────────────────────────────────────────────────
  final bool isSaving;
  final bool isLoading;
  final String? errorMessage;

  /// Returns `true` when the form is in edit mode.
  bool get isEditMode => categoryId != null;

  AdminCategoryFormState copyWith({
    String? categoryId,
    String? name,
    Object? imageUrl = _sentinel,
    bool? isActive,
    bool? isSaving,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminCategoryFormState(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      isActive: isActive ?? this.isActive,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// Sentinel value to distinguish "not provided" from explicit null.
const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages form state for [AdminCategoryFormScreen].
///
/// Handles both create mode (categoryId == null) and edit mode
/// (categoryId != null).
///
/// Satisfies Requirements 3.2, 3.3, and 3.4.
@riverpod
class AdminCategoryFormNotifier extends _$AdminCategoryFormNotifier {
  @override
  AdminCategoryFormState build() {
    return const AdminCategoryFormState();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Initialises the form for create mode (blank fields, isActive = true).
  void initCreate() {
    state = const AdminCategoryFormState();
  }

  /// Loads an existing category into the form for edit mode.
  ///
  /// Reads from the already-loaded category list in
  /// [adminCategoryNotifierProvider] to avoid an extra Firestore round-trip.
  Future<void> loadCategory(String categoryId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Try to find the category in the already-loaded list first.
      final categoryListState =
          ref.read(adminCategoryNotifierProvider).valueOrNull;
      final category = categoryListState?.allCategories
          .where((c) => c.id == categoryId)
          .firstOrNull;

      if (category == null) {
        // Fallback: fetch directly from the repository.
        final repository = ref.read(adminCategoryRepositoryProvider);
        final categories = await repository.getAllCategories();
        final found = categories.where((c) => c.id == categoryId).firstOrNull;

        if (found == null) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Category not found.',
          );
          return;
        }

        state = AdminCategoryFormState(
          categoryId: categoryId,
          name: found.name,
          imageUrl: found.imageUrl,
          isActive: found.isActive,
          isLoading: false,
        );
        return;
      }

      state = AdminCategoryFormState(
        categoryId: categoryId,
        name: category.name,
        imageUrl: category.imageUrl,
        isActive: category.isActive,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load category: $e',
      );
    }
  }

  // ── Field setters ─────────────────────────────────────────────────────────

  void setName(String value) => state = state.copyWith(name: value);

  void setImageUrl(String? value) =>
      state = state.copyWith(imageUrl: value ?? _sentinel);

  void setIsActive(bool value) => state = state.copyWith(isActive: value);

  // ── Validation ────────────────────────────────────────────────────────────

  /// Returns an error message if the form is invalid, or `null` if valid.
  String? validate() {
    if (state.name.trim().isEmpty) return 'Name is required.';
    return null;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Validates the form and saves the category.
  ///
  /// Returns `true` on success, `false` on validation failure or error.
  /// Calls `adminManageCategory` with action='create' in create mode or
  /// action='update' in edit mode.
  Future<bool> save() async {
    final validationError = validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repository = ref.read(adminCategoryRepositoryProvider);

      final data = <String, dynamic>{
        'name': state.name.trim(),
        if (state.imageUrl != null) 'imageUrl': state.imageUrl,
      };

      if (state.isEditMode) {
        final useCase = UpdateCategoryUseCase(repository);
        await useCase(state.categoryId!, data);
      } else {
        final useCase = CreateCategoryUseCase(repository);
        await useCase(data);
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _friendlyError(e),
      );
      return false;
    }
  }

  // ── Toggle active ─────────────────────────────────────────────────────────

  /// Toggles the active state of the category.
  ///
  /// In edit mode, calls `adminManageCategory` with action='deactivate' or
  /// action='activate'. Satisfies Requirement 3.3.
  Future<bool> toggleActive() async {
    if (!state.isEditMode) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repository = ref.read(adminCategoryRepositoryProvider);

      if (state.isActive) {
        await repository.deactivateCategory(state.categoryId!);
        state = state.copyWith(isSaving: false, isActive: false);
      } else {
        await repository.activateCategory(state.categoryId!);
        state = state.copyWith(isSaving: false, isActive: true);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _friendlyError(e),
      );
      return false;
    }
  }

  /// Clears any current error message.
  void clearError() => state = state.copyWith(clearError: true);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a raw exception to a user-friendly message.
  ///
  /// Surfaces the Cloud Function error message when available (e.g. the
  /// duplicate-name error from `adminManageCategory`).
  String _friendlyError(Object e) {
    final message = e.toString();
    // FirebaseFunctionsException messages are wrapped in the toString output.
    // Extract the human-readable part after the last colon if present.
    final colonIndex = message.lastIndexOf(': ');
    if (colonIndex != -1 && colonIndex < message.length - 2) {
      return message.substring(colonIndex + 2);
    }
    return message;
  }
}
