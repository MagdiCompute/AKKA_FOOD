import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/meal_image_upload_service.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/nutritional_info.dart';
import '../notifiers/catalog_notifier.dart';
import '../notifiers/category_providers.dart';

// ---------------------------------------------------------------------------
// MealImageUploadService provider
// ---------------------------------------------------------------------------

/// Provides a [MealImageUploadService] backed by [FirebaseStorage.instance].
///
/// Override in tests via `ProviderScope(overrides: [...])`.
final mealImageUploadServiceProvider = Provider<MealImageUploadService>(
  (ref) => MealImageUploadService(FirebaseStorage.instance),
);

// ---------------------------------------------------------------------------
// Dietary tag constants
// ---------------------------------------------------------------------------

const _kDietaryTags = [
  'vegetarian',
  'vegan',
  'gluten-free',
  'spicy',
  'halal',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Create / edit form for a single meal in the catalog.
///
/// Pass [mealId] == null to create a new meal; pass a non-null [mealId] to
/// edit an existing one.
///
/// Satisfies Requirements 7.2 — Admin meal form with image picker (1–5 images),
/// all fields, and featured toggle.
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
  final _picker = ImagePicker();

  // Text controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinsController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatsController;
  late final TextEditingController _featuredOrderController;

  // Form state
  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isFeatured = false;
  final List<String> _selectedDietaryTags = [];
  bool _showNutritionalInfo = false;

  // Images: existing URLs (edit mode) + newly picked local files
  final List<String> _existingImageUrls = [];
  final List<XFile> _newImages = [];

  // UI state
  bool _isSaving = false;
  bool _isLoadingMeal = false;
  bool _controllersInitialised = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinsController = TextEditingController();
    _carbsController = TextEditingController();
    _fatsController = TextEditingController();
    _featuredOrderController = TextEditingController();

    if (widget.mealId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMeal());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _featuredOrderController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Load meal for edit mode
  // ---------------------------------------------------------------------------

  Future<void> _loadMeal() async {
    if (widget.mealId == null) return;
    setState(() => _isLoadingMeal = true);

    try {
      final meal =
          await ref.read(mealRepositoryProvider).getMealById(widget.mealId!);
      if (meal == null || !mounted) return;
      _populateFromMeal(meal);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load meal: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMeal = false);
    }
  }

  void _populateFromMeal(Meal meal) {
    if (_controllersInitialised) return;
    _nameController.text = meal.name;
    _descriptionController.text = meal.description;
    _priceController.text =
        meal.price == 0 ? '' : meal.price.toStringAsFixed(0);
    _featuredOrderController.text =
        meal.featuredOrder == 0 ? '' : meal.featuredOrder.toString();

    final ni = meal.nutritionalInfo;
    if (ni != null) {
      _caloriesController.text =
          ni.calories == 0 ? '' : ni.calories.toStringAsFixed(0);
      _proteinsController.text =
          ni.proteins == 0 ? '' : ni.proteins.toStringAsFixed(1);
      _carbsController.text =
          ni.carbohydrates == 0 ? '' : ni.carbohydrates.toStringAsFixed(1);
      _fatsController.text =
          ni.fats == 0 ? '' : ni.fats.toStringAsFixed(1);
      _showNutritionalInfo = true;
    }

    setState(() {
      _selectedCategoryId = meal.categoryId.isEmpty ? null : meal.categoryId;
      _isAvailable = meal.isAvailable;
      _isFeatured = meal.isFeatured;
      _selectedDietaryTags
        ..clear()
        ..addAll(meal.dietaryTags);
      _existingImageUrls
        ..clear()
        ..addAll(meal.imageUrls);
      _controllersInitialised = true;
    });
  }

  // ---------------------------------------------------------------------------
  // Image picker
  // ---------------------------------------------------------------------------

  int get _totalImageCount => _existingImageUrls.length + _newImages.length;

  Future<void> _pickImage() async {
    if (_totalImageCount >= 5) return;

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _newImages.add(picked));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Require at least 1 image.
    if (_totalImageCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(mealRepositoryProvider);
      final uploadService = ref.read(mealImageUploadServiceProvider);
      final now = DateTime.now();

      // Determine the meal ID up-front so we can use it as the Storage path.
      final mealId = widget.mealId ??
          FirebaseFirestore.instance.collection('meals').doc().id;

      // Upload any newly picked images to Firebase Storage.
      // Path: /meals/{mealId}/{index}.jpg
      // New images are appended after existing ones.
      List<String> uploadedUrls = [];
      if (_newImages.isNotEmpty) {
        uploadedUrls = await uploadService.uploadMealImages(
          mealId: mealId,
          images: _newImages,
          startIndex: _existingImageUrls.length,
        );
      }

      // Combine existing (retained) URLs with newly uploaded ones.
      final imageUrls = [..._existingImageUrls, ...uploadedUrls];

      final nutritionalInfo = _buildNutritionalInfo();

      if (widget.mealId == null) {
        // Create mode: use the pre-generated Firestore document ID.
        final meal = Meal(
          id: mealId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          categoryId: _selectedCategoryId!,
          imageUrls: imageUrls,
          isAvailable: _isAvailable,
          isFeatured: _isFeatured,
          featuredOrder: _isFeatured
              ? (int.tryParse(_featuredOrderController.text.trim()) ?? 0)
              : 0,
          nutritionalInfo: nutritionalInfo,
          dietaryTags: List<String>.from(_selectedDietaryTags),
          popularityScore: 0,
          createdAt: now,
          updatedAt: now,
        );

        await repository.createMeal(meal);
      } else {
        // Edit mode: load the existing meal and apply changes.
        final existing =
            await repository.getMealById(widget.mealId!);
        if (existing == null) throw Exception('Meal not found.');

        final updated = existing.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          categoryId: _selectedCategoryId!,
          imageUrls: imageUrls,
          isAvailable: _isAvailable,
          isFeatured: _isFeatured,
          featuredOrder: _isFeatured
              ? (int.tryParse(_featuredOrderController.text.trim()) ?? 0)
              : existing.featuredOrder,
          nutritionalInfo: nutritionalInfo,
          dietaryTags: List<String>.from(_selectedDietaryTags),
          updatedAt: now,
        );

        await repository.updateMeal(updated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal saved')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save meal: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  NutritionalInfo? _buildNutritionalInfo() {
    final calories = double.tryParse(_caloriesController.text.trim());
    final proteins = double.tryParse(_proteinsController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fats = double.tryParse(_fatsController.text.trim());

    // Only create nutritional info if at least one field is filled.
    if (calories == null && proteins == null && carbs == null && fats == null) {
      return null;
    }

    return NutritionalInfo(
      calories: calories ?? 0,
      proteins: proteins ?? 0,
      carbohydrates: carbs ?? 0,
      fats: fats ?? 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.mealId != null;
    final isBusy = _isSaving || _isLoadingMeal;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Meal' : 'Add Meal'),
        actions: [
          if (isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: _onSave,
            ),
        ],
      ),
      body: _isLoadingMeal
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // ── Basic info ──────────────────────────────────────────
                  _SectionHeader(label: 'Basic Info'),
                  const SizedBox(height: 8),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),

                  // Price
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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Category dropdown
                  _CategoryDropdown(
                    selectedCategoryId: _selectedCategoryId,
                    onChanged: (id) =>
                        setState(() => _selectedCategoryId = id),
                  ),
                  const SizedBox(height: 24),

                  // ── Images ──────────────────────────────────────────────
                  _SectionHeader(label: 'Images (1–5)'),
                  const SizedBox(height: 8),
                  _ImagePickerSection(
                    existingUrls: _existingImageUrls,
                    newImages: _newImages,
                    onPickImage: _pickImage,
                    onRemoveExisting: _removeExistingImage,
                    onRemoveNew: _removeNewImage,
                  ),
                  const SizedBox(height: 24),

                  // ── Dietary tags ─────────────────────────────────────────
                  _SectionHeader(label: 'Dietary Tags'),
                  const SizedBox(height: 8),
                  _DietaryTagsWrap(
                    selectedTags: _selectedDietaryTags,
                    onToggle: (tag) {
                      setState(() {
                        if (_selectedDietaryTags.contains(tag)) {
                          _selectedDietaryTags.remove(tag);
                        } else {
                          _selectedDietaryTags.add(tag);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Nutritional info (expandable) ────────────────────────
                  _NutritionalInfoSection(
                    isExpanded: _showNutritionalInfo,
                    onToggle: () => setState(
                      () => _showNutritionalInfo = !_showNutritionalInfo,
                    ),
                    caloriesController: _caloriesController,
                    proteinsController: _proteinsController,
                    carbsController: _carbsController,
                    fatsController: _fatsController,
                  ),
                  const SizedBox(height: 24),

                  // ── Availability & Featured ──────────────────────────────
                  _SectionHeader(label: 'Availability & Visibility'),
                  SwitchListTile(
                    title: const Text('Available'),
                    subtitle: const Text(
                      'Customers can see and order this meal',
                    ),
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Featured'),
                    subtitle: const Text(
                      'Show this meal in the Featured section',
                    ),
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Featured order (only when featured)
                  if (_isFeatured) ...[
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

/// Dropdown populated from [categoriesProvider].
class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({
    required this.selectedCategoryId,
    required this.onChanged,
  });

  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Failed to load categories: $e',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (categories) {
        // Ensure the selected ID is still valid in the loaded list.
        final validId = categories.any((c) => c.id == selectedCategoryId)
            ? selectedCategoryId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: validId,
          decoration: const InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Select a category'),
          items: categories
              .map(
                (cat) => DropdownMenuItem<String>(
                  value: cat.id,
                  child: Text(cat.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Category is required' : null,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Image picker section
// ---------------------------------------------------------------------------

/// Shows existing network images and newly picked local images, with add/remove
/// controls. Actual upload to Firebase Storage is handled in task 7.4.
class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.existingUrls,
    required this.newImages,
    required this.onPickImage,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<String> existingUrls;
  final List<XFile> newImages;
  final VoidCallback onPickImage;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  int get _total => existingUrls.length + newImages.length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canAddMore = _total < 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_total/5 images',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Existing network images
              for (int i = 0; i < existingUrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ImageSlot(
                    child: Image.network(
                      existingUrls[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                      ),
                    ),
                    onRemove: () => onRemoveExisting(i),
                  ),
                ),

              // Newly picked local images
              for (int i = 0; i < newImages.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ImageSlot(
                    child: Image.file(
                      File(newImages[i].path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    onRemove: () => onRemoveNew(i),
                  ),
                ),

              // Add image button
              if (canAddMore)
                _AddImageButton(onTap: onPickImage),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Image slot (thumbnail + remove button)
// ---------------------------------------------------------------------------

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 80, height: 80, child: child),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add image button
// ---------------------------------------------------------------------------

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dietary tags wrap
// ---------------------------------------------------------------------------

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
// Nutritional info section (expandable)
// ---------------------------------------------------------------------------

class _NutritionalInfoSection extends StatelessWidget {
  const _NutritionalInfoSection({
    required this.isExpanded,
    required this.onToggle,
    required this.caloriesController,
    required this.proteinsController,
    required this.carbsController,
    required this.fatsController,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final TextEditingController caloriesController;
  final TextEditingController proteinsController;
  final TextEditingController carbsController;
  final TextEditingController fatsController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'Nutritional Info (per serving)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NutrientField(
                  controller: caloriesController,
                  label: 'Calories',
                  suffix: 'kcal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NutrientField(
                  controller: proteinsController,
                  label: 'Proteins',
                  suffix: 'g',
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
                  label: 'Carbohydrates',
                  suffix: 'g',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NutrientField(
                  controller: fatsController,
                  label: 'Fats',
                  suffix: 'g',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrient field
// ---------------------------------------------------------------------------

class _NutrientField extends StatelessWidget {
  const _NutrientField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

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
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final parsed = double.tryParse(v.trim());
        if (parsed == null || parsed < 0) {
          return 'Must be ≥ 0';
        }
        return null;
      },
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
