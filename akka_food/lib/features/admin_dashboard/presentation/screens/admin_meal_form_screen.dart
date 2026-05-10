import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../notifiers/admin_meal_form_notifier.dart';
import '../notifiers/admin_meal_notifier.dart';
import '../widgets/meal_image_upload_widget.dart';

// ---------------------------------------------------------------------------
// Dietary tag constants
// ---------------------------------------------------------------------------

const _kDietaryTags = [
  'Vegetarian',
  'Vegan',
  'Gluten-Free',
  'Spicy',
  'Halal',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Create / edit form for a single meal.
///
/// Pass [mealId] == null to create a new meal; pass a non-null [mealId] to
/// edit an existing one.
///
/// Satisfies Requirements 2.2, 2.3, 2.5, and 2.6.
class AdminMealFormScreen extends ConsumerStatefulWidget {
  const AdminMealFormScreen({super.key, this.mealId});

  /// `null` → create mode; non-null → edit mode.
  final String? mealId;

  @override
  ConsumerState<AdminMealFormScreen> createState() =>
      _AdminMealFormScreenState();
}

class _AdminMealFormScreenState extends ConsumerState<AdminMealFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // For new meals, generate a temporary ID used as the Firebase Storage folder.
  // This is replaced by the real Firestore ID after the meal is saved.
  late final String _effectiveMealId;

  // Text controllers — kept in sync with notifier state on load.
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _featuredOrderController;

  bool _controllersInitialised = false;

  @override
  void initState() {
    super.initState();
    // Use the real meal ID in edit mode; generate a temp ID for new meals.
    _effectiveMealId = widget.mealId ??
        'temp_${DateTime.now().millisecondsSinceEpoch}';

    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _featuredOrderController = TextEditingController();

    // Initialise the notifier after the first frame so the provider is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.mealId != null) {
        ref
            .read(adminMealFormNotifierProvider.notifier)
            .loadMeal(widget.mealId!);
      } else {
        ref.read(adminMealFormNotifierProvider.notifier).initCreate();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _featuredOrderController.dispose();
    super.dispose();
  }

  // ── Sync controllers from notifier state (edit mode load) ─────────────────

  void _syncControllers(AdminMealFormState formState) {
    if (_controllersInitialised) return;
    if (formState.isLoading) return;
    if (formState.isEditMode && formState.name.isEmpty) return;

    _nameController.text = formState.name;
    _descriptionController.text = formState.description;
    _priceController.text = formState.price;
    _caloriesController.text = formState.calories;
    _proteinController.text = formState.protein;
    _carbsController.text = formState.carbs;
    _fatController.text = formState.fat;
    _featuredOrderController.text = formState.featuredOrder;
    _controllersInitialised = true;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    // Trigger Flutter form validation (required fields, etc.).
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(adminMealFormNotifierProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.mealId == null
                ? 'Meal created successfully.'
                : 'Meal updated successfully.',
          ),
        ),
      );
      context.pop();
    } else {
      final error = ref.read(adminMealFormNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save meal. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _onSave,
          ),
        ),
      );
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text(
          'Are you sure you want to delete this meal? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final notifier = ref.read(adminMealFormNotifierProvider.notifier);
    final success = await notifier.delete();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal deleted.')),
      );
      context.pop();
    } else {
      final error = ref.read(adminMealFormNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to delete meal. Please try again.'),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(adminMealFormNotifierProvider);
    final notifier = ref.read(adminMealFormNotifierProvider.notifier);

    // Sync text controllers once the meal data is loaded.
    _syncControllers(formState);

    final isEditMode = widget.mealId != null;
    final isBusy = formState.isSaving || formState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Meal' : 'New Meal'),
        actions: [
          // ── Delete button (edit mode only) ───────────────────────────────
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete meal',
              onPressed: isBusy ? null : _onDelete,
            ),
          // ── Save button ──────────────────────────────────────────────────
          isBusy
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _onSave,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // ── Name ─────────────────────────────────────────────────
                  _SectionHeader(label: 'Basic Info'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: notifier.setName,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // ── Description ──────────────────────────────────────────
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: notifier.setDescription,
                  ),
                  const SizedBox(height: 12),

                  // ── Price ─────────────────────────────────────────────────
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      suffixText: 'XOF',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    onChanged: notifier.setPrice,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Category ──────────────────────────────────────────────
                  _CategoryDropdown(
                    selectedCategory: formState.category.isEmpty
                        ? null
                        : formState.category,
                    onChanged: notifier.setCategory,
                  ),
                  const SizedBox(height: 24),

                  // ── Images ───────────────────────────────────────────────
                  _SectionHeader(label: 'Images'),
                  const SizedBox(height: 8),
                  MealImageUploadWidget(mealId: _effectiveMealId),
                  const SizedBox(height: 24),

                  // ── Dietary tags ──────────────────────────────────────────
                  _SectionHeader(label: 'Dietary Tags'),
                  const SizedBox(height: 8),
                  _DietaryTagsWrap(
                    selectedTags: formState.dietaryTags,
                    onToggle: notifier.toggleDietaryTag,
                  ),
                  const SizedBox(height: 24),

                  // ── Nutritional info ──────────────────────────────────────
                  _SectionHeader(label: 'Nutritional Info (per serving)'),
                  const SizedBox(height: 8),
                  _NutritionalInfoFields(
                    caloriesController: _caloriesController,
                    proteinController: _proteinController,
                    carbsController: _carbsController,
                    fatController: _fatController,
                    onCaloriesChanged: notifier.setCalories,
                    onProteinChanged: notifier.setProtein,
                    onCarbsChanged: notifier.setCarbs,
                    onFatChanged: notifier.setFat,
                  ),
                  const SizedBox(height: 24),

                  // ── Availability ──────────────────────────────────────────
                  _SectionHeader(label: 'Availability & Visibility'),
                  SwitchListTile(
                    title: const Text('Available'),
                    subtitle: const Text(
                      'Customers can see and order this meal',
                    ),
                    value: formState.isAvailable,
                    onChanged: notifier.setIsAvailable,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // ── Featured ──────────────────────────────────────────────
                  SwitchListTile(
                    title: const Text('Featured'),
                    subtitle: const Text(
                      'Show this meal in the Featured section',
                    ),
                    value: formState.isFeatured,
                    onChanged: notifier.setIsFeatured,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // ── Featured order (only when featured) ───────────────────
                  if (formState.isFeatured) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _featuredOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Featured Order',
                        helperText:
                            'Lower numbers appear first (0 = highest priority)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: notifier.setFeaturedOrder,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final parsed = int.tryParse(v.trim());
                        if (parsed == null || parsed < 0) {
                          return 'Enter a non-negative integer';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category dropdown
// ---------------------------------------------------------------------------

/// Dropdown that loads categories from [adminMealNotifierProvider].
class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({
    required this.selectedCategory,
    required this.onChanged,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealState = ref.watch(adminMealNotifierProvider);

    final categories = mealState.valueOrNull?.categories ?? [];

    return DropdownButtonFormField<String>(
      initialValue: (selectedCategory != null && categories.contains(selectedCategory))
          ? selectedCategory
          : null,
      decoration: const InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select a category'),
      items: categories
          .map(
            (cat) => DropdownMenuItem<String>(
              value: cat,
              child: Text(cat),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Category is required' : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Dietary tags wrap
// ---------------------------------------------------------------------------

/// Wrap of [FilterChip]s for common dietary tags.
class _DietaryTagsWrap extends StatelessWidget {
  const _DietaryTagsWrap({
    required this.selectedTags,
    required this.onToggle,
  });

  final List<String> selectedTags;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _kDietaryTags.map((tag) {
        return FilterChip(
          label: Text(tag),
          selected: selectedTags.contains(tag),
          onSelected: (_) => onToggle(tag),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutritional info fields
// ---------------------------------------------------------------------------

/// Four numeric fields for calories, protein, carbs, and fat.
class _NutritionalInfoFields extends StatelessWidget {
  const _NutritionalInfoFields({
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    required this.onCaloriesChanged,
    required this.onProteinChanged,
    required this.onCarbsChanged,
    required this.onFatChanged,
  });

  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final ValueChanged<String> onCaloriesChanged;
  final ValueChanged<String> onProteinChanged;
  final ValueChanged<String> onCarbsChanged;
  final ValueChanged<String> onFatChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NutrientField(
                controller: caloriesController,
                label: 'Calories',
                suffix: 'kcal',
                onChanged: onCaloriesChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NutrientField(
                controller: proteinController,
                label: 'Protein',
                suffix: 'g',
                onChanged: onProteinChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NutrientField(
                controller: carbsController,
                label: 'Carbs',
                suffix: 'g',
                onChanged: onCarbsChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NutrientField(
                controller: fatController,
                label: 'Fat',
                suffix: 'g',
                onChanged: onFatChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NutrientField extends StatelessWidget {
  const _NutrientField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: onChanged,
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
