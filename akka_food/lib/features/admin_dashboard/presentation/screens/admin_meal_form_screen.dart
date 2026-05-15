import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../notifiers/admin_meal_form_notifier.dart';
import '../widgets/meal_image_upload_widget.dart';

// ---------------------------------------------------------------------------
// Dietary tag constants
// ---------------------------------------------------------------------------

const _kDietaryTags = [
  'Végétarien',
  'Végan',
  'Sans gluten',
  'Épicé',
  'Halal',
];

// ---------------------------------------------------------------------------
// Categories provider — reads directly from Firestore
// ---------------------------------------------------------------------------

/// Fetches active categories from Firestore for the category dropdown.
final _firestoreCategoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('categories')
      .where('isActive', isEqualTo: true)
      .get();
  return snapshot.docs.map((doc) => {'id': doc.id, 'name': doc.data()['name'] ?? doc.id}).toList();
});

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
        _loadMealDirectly(widget.mealId!);
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

  /// Loads meal data directly from Firestore and populates controllers.
  Future<void> _loadMealDirectly(String mealId) async {
    final notifier = ref.read(adminMealFormNotifierProvider.notifier);
    notifier.loadMeal(mealId);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('meals')
          .doc(mealId)
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        final data = doc.data()!;
        _nameController.text = data['name'] as String? ?? '';
        _descriptionController.text = data['description'] as String? ?? '';
        final price = data['price'];
        _priceController.text = price != null ? price.toString() : '';
        final nutritional = data['nutritionalInfo'] as Map<String, dynamic>?;
        if (nutritional != null) {
          _caloriesController.text = nutritional['calories']?.toString() ?? '';
          _proteinController.text = nutritional['protein']?.toString() ?? '';
          _carbsController.text = nutritional['carbs']?.toString() ?? '';
          _fatController.text = nutritional['fat']?.toString() ?? '';
        }
        _featuredOrderController.text = (data['featuredOrder'] ?? '').toString();
        _controllersInitialised = true;
        setState(() {});
      }
    } catch (_) {
      // Fallback to notifier-based loading
    }
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

    // Sync controller values to notifier state before saving
    final notifier = ref.read(adminMealFormNotifierProvider.notifier);
    notifier.setName(_nameController.text);
    notifier.setDescription(_descriptionController.text);
    notifier.setPrice(_priceController.text);
    notifier.setCalories(_caloriesController.text);
    notifier.setProtein(_proteinController.text);
    notifier.setCarbs(_carbsController.text);
    notifier.setFat(_fatController.text);
    notifier.setFeaturedOrder(_featuredOrderController.text);

    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.mealId == null
                ? 'Plat créé avec succès.'
                : 'Plat mis à jour avec succès.',
          ),
        ),
      );
      context.pop();
    } else {
      final error = ref.read(adminMealFormNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Échec de l\'enregistrement. Veuillez réessayer.'),
          action: SnackBarAction(
            label: 'Réessayer',
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
        title: const Text('Supprimer le plat'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce plat ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
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
        const SnackBar(content: Text('Plat supprimé.')),
      );
      context.pop();
    } else {
      final error = ref.read(adminMealFormNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Échec de la suppression. Veuillez réessayer.'),
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
        title: Text(isEditMode ? 'Modifier le plat' : 'Nouveau plat'),
        actions: [
          // ── Delete button (edit mode only) ───────────────────────────────
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer le plat',
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
                  child: const Text('Enregistrer'),
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
                  _SectionHeader(label: 'Informations de base'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: notifier.setName,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
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
                      labelText: 'Prix *',
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
                        return 'Le prix est requis';
                      }
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Entrez un prix valide';
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
                  _SectionHeader(label: 'Tags alimentaires'),
                  const SizedBox(height: 8),
                  _DietaryTagsWrap(
                    selectedTags: formState.dietaryTags,
                    onToggle: notifier.toggleDietaryTag,
                  ),
                  const SizedBox(height: 24),

                  // ── Nutritional info ──────────────────────────────────────
                  _SectionHeader(label: 'Info nutritionnelle (par portion)'),
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
                  _SectionHeader(label: 'Disponibilité & Visibilité'),
                  SwitchListTile(
                    title: const Text('Disponible'),
                    subtitle: const Text(
                      'Les clients peuvent voir et commander ce plat',
                    ),
                    value: formState.isAvailable,
                    onChanged: notifier.setIsAvailable,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // ── Featured ──────────────────────────────────────────────
                  SwitchListTile(
                    title: const Text('À la une'),
                    subtitle: const Text(
                      'Afficher ce plat dans la section À la une',
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
                        labelText: 'Ordre d\'affichage',
                        helperText:
                            'Les nombres plus petits apparaissent en premier (0 = priorité maximale)',
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
                          return 'Entrez un nombre entier positif';
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

/// Dropdown that loads categories from Firestore directly.
class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({
    required this.selectedCategory,
    required this.onChanged,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(_firestoreCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Échec du chargement des catégories : $e'),
      data: (categories) {
        return DropdownButtonFormField<String>(
          value: (selectedCategory != null &&
                  categories.any((c) => c['id'] == selectedCategory))
              ? selectedCategory
              : null,
          decoration: const InputDecoration(
            labelText: 'Catégorie *',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Sélectionner une catégorie'),
          items: categories
              .map(
                (cat) => DropdownMenuItem<String>(
                  value: cat['id'] as String,
                  child: Text(cat['name'] as String),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'La catégorie est requise' : null,
        );
      },
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
                label: 'Protéines',
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
                label: 'Glucides',
                suffix: 'g',
                onChanged: onCarbsChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NutrientField(
                controller: fatController,
                label: 'Lipides',
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
