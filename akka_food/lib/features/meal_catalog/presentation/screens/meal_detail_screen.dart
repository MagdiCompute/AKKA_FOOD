import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akka_food/core/widgets/animated_add_to_cart_button.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/nutritional_info.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/catalog_notifier.dart';

/// Full-screen detail view for a single meal.
///
/// Accepts a [mealId] path parameter (from go_router `/meals/:id`).
/// Fetches the meal via [mealDetailProvider] and renders:
/// - Image gallery with swipe support and page indicator dots.
/// - Meal name, price, availability badge, description.
/// - Dietary tags as colored chips.
/// - Nutritional info in a 2×2 card grid (when available).
/// - A bottom bar with an "Add to Cart" button (disabled when unavailable).
class MealDetailScreen extends ConsumerStatefulWidget {
  const MealDetailScreen({super.key, required this.mealId});

  /// The meal's Firestore document ID, injected by go_router.
  final String mealId;

  @override
  ConsumerState<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends ConsumerState<MealDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mealAsync = ref.watch(mealDetailProvider(widget.mealId));

    return mealAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Détail du plat')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Détail du plat')),
        body: _ErrorBody(error: error.toString()),
      ),
      data: (meal) {
        if (meal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détail du plat')),
            body: const Center(child: Text('Plat introuvable.')),
          );
        }
        return _MealDetailBody(
          meal: meal,
          pageController: _pageController,
          currentPage: _currentPage,
          onPageChanged: (page) => setState(() => _currentPage = page),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Main body — extracted to keep build() readable.
// ---------------------------------------------------------------------------

class _MealDetailBody extends StatelessWidget {
  const _MealDetailBody({
    required this.meal,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final Meal meal;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          meal.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottomNavigationBar: _AddToCartBar(meal: meal),
      body: CustomScrollView(
        slivers: [
          // ── Image gallery ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ImageGallery(
              imageUrls: meal.imageUrls,
              pageController: pageController,
              currentPage: currentPage,
              onPageChanged: onPageChanged,
            ),
          ),

          // ── Content padding ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Name ────────────────────────────────────────────────
                Text(
                  meal.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // ── Price + availability row ─────────────────────────────
                Row(
                  children: [
                    Text(
                      '${meal.price.toStringAsFixed(0)} XOF',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(width: 12),
                    _AvailabilityBadge(isAvailable: meal.isAvailable),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Description ──────────────────────────────────────────
                Text(
                  meal.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // ── Dietary tags ─────────────────────────────────────────
                if (meal.dietaryTags.isNotEmpty) ...[
                  _DietaryTagsRow(tags: meal.dietaryTags),
                  const SizedBox(height: 16),
                ],

                // ── Nutritional info ─────────────────────────────────────
                if (meal.nutritionalInfo != null) ...[
                  _NutritionalInfoSection(info: meal.nutritionalInfo!),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image gallery with PageView + indicator dots.
// ---------------------------------------------------------------------------

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.imageUrls,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<String> imageUrls;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.isNotEmpty ? imageUrls : <String>[];
    final hasMultiple = urls.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 280,
          child: urls.isEmpty
              ? _PlaceholderImage()
              : PageView.builder(
                  controller: pageController,
                  itemCount: urls.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) {
                    return Image.network(
                      urls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _PlaceholderImage(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );
                  },
                ),
        ),

        // Page indicator dots — only shown when more than one image.
        if (hasMultiple)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(urls.length, (index) {
                final isActive = index == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 10 : 6,
                  height: isActive ? 10 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.restaurant, size: 64, color: Colors.grey),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Availability badge.
// ---------------------------------------------------------------------------

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Indisponible',
        style: TextStyle(
          color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dietary tags row.
// ---------------------------------------------------------------------------

class _DietaryTagsRow extends StatelessWidget {
  const _DietaryTagsRow({required this.tags});

  final List<String> tags;

  /// Maps a dietary tag label to its chip color.
  MaterialColor _colorForTag(String tag) {
    switch (tag.toLowerCase()) {
      case 'vegetarian':
        return Colors.green;
      case 'vegan':
        return Colors.lightGreen;
      case 'gluten-free':
        return Colors.orange;
      case 'spicy':
        return Colors.red;
      case 'halal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags.map((tag) {
        final color = _colorForTag(tag);
        return Chip(
          label: Text(
            tag,
            style: TextStyle(
              color: color.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: color.withValues(alpha: 0.12),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutritional info section — 2×2 grid of cards.
// ---------------------------------------------------------------------------

class _NutritionalInfoSection extends StatelessWidget {
  const _NutritionalInfoSection({required this.info});

  final NutritionalInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations nutritionnelles',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _NutrientCard(
              label: 'Calories',
              value: info.calories.toStringAsFixed(0),
              unit: 'kcal',
              icon: Icons.local_fire_department,
              color: Colors.orange,
            ),
            _NutrientCard(
              label: 'Protéines',
              value: info.proteins.toStringAsFixed(1),
              unit: 'g',
              icon: Icons.fitness_center,
              color: Colors.blue,
            ),
            _NutrientCard(
              label: 'Glucides',
              value: info.carbohydrates.toStringAsFixed(1),
              unit: 'g',
              icon: Icons.grain,
              color: Colors.amber,
            ),
            _NutrientCard(
              label: 'Lipides',
              value: info.fats.toStringAsFixed(1),
              unit: 'g',
              icon: Icons.opacity,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$value $unit',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.shade700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add to Cart bottom bar.
// ---------------------------------------------------------------------------

class _AddToCartBar extends ConsumerWidget {
  const _AddToCartBar({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedAddToCartButton(
      enabled: meal.isAvailable,
      onPressed: () {
        ref.read(cartNotifierProvider.notifier).addItem(meal);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Error body.
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Échec du chargement du plat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
