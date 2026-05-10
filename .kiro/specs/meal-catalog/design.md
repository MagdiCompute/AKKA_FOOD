# Design Document — Meal Catalog

## Overview

The Meal Catalog is the primary browsing surface of AKKA Food. It follows clean architecture (Presentation → Domain → Data). Firestore stores meal and category data. Algolia provides full-text search. Riverpod manages UI state. The catalog integrates with the Cart, Recommendation Engine, and Admin Dashboard.

---

## Architecture

```
Presentation Layer
  └── Screens: CatalogScreen, MealDetailScreen, SearchScreen, FilterBottomSheet, AdminMealFormScreen, AdminCategoryFormScreen
  └── Widgets: MealCard, CategoryChip, FeaturedBanner, RecommendedSection, FilterChip
  └── State: CatalogNotifier, MealDetailNotifier, SearchNotifier, AdminMealNotifier

Domain Layer
  └── Entities: Meal, Category, NutritionalInfo, FeaturedMeal
  └── Use Cases: GetMealsUseCase, GetMealDetailUseCase, SearchMealsUseCase,
                 FilterMealsUseCase, SortMealsUseCase, GetCategoriesUseCase,
                 GetFeaturedMealsUseCase, GetRecommendedMealsUseCase,
                 AdminCreateMealUseCase, AdminUpdateMealUseCase, AdminDeleteMealUseCase,
                 AdminManageCategoryUseCase
  └── Repository Interfaces: IMealRepository, ICategoryRepository, IFeaturedRepository

Data Layer
  └── MealRepository, CategoryRepository, FeaturedRepository
  └── FirestoreMealDataSource, AlgoliaSearchDataSource
  └── HiveCatalogCache (local cache)
```

---

## Data Models

### Meal
```dart
class Meal {
  final String id;
  final String name;
  final String description;
  final double price;          // XOF
  final String categoryId;
  final List<String> imageUrls;
  final bool isAvailable;
  final bool isFeatured;
  final int featuredOrder;     // admin-defined display order
  final NutritionalInfo? nutritionalInfo;
  final List<String> dietaryTags; // ['vegetarian', 'vegan', 'gluten-free', 'spicy', 'halal']
  final int popularityScore;   // incremented on each order
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Category
```dart
class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
}
```

### NutritionalInfo
```dart
class NutritionalInfo {
  final double calories;
  final double proteins;
  final double carbohydrates;
  final double fats;
}
```

### MealFilter
```dart
class MealFilter {
  final List<String> categoryIds;
  final double? minPrice;
  final double? maxPrice;
  final bool availableOnly;
  final List<String> dietaryTags;
}

enum MealSortOption {
  priceAsc,
  priceDesc,
  popularityDesc,
  newestFirst,
}
```

---

## Firestore Collections

```
/meals/{mealId}
  - name: string (unique)
  - description: string
  - price: number (XOF, > 0)
  - categoryId: string
  - imageUrls: string[]
  - isAvailable: bool
  - isFeatured: bool
  - featuredOrder: number
  - nutritionalInfo: { calories, proteins, carbohydrates, fats }
  - dietaryTags: string[]
  - popularityScore: number
  - createdAt: timestamp
  - updatedAt: timestamp

/categories/{categoryId}
  - name: string (unique)
  - imageUrl: string?
  - isActive: bool
  - createdAt: timestamp
```

---

## Search Implementation

**Algolia** indexes the `/meals` collection via a Firestore → Algolia sync Cloud Function triggered on meal create/update/delete.

Algolia index attributes:
- Searchable: `name`, `description`, `dietaryTags`
- Filterable: `categoryId`, `isAvailable`, `dietaryTags`, `price`
- Sortable: `price`, `popularityScore`, `createdAt`

Flutter: `algolia` package. Debounce: 300ms before firing search query.

Fallback: If Algolia is unavailable, fall back to Firestore `where('name', isGreaterThanOrEqualTo: query)` prefix search.

---

## Filter & Sort Strategy

Filters and sorts are applied client-side on the cached meal list for instant response, with a server-side Firestore query as the source of truth on initial load and refresh.

```dart
class CatalogState {
  final List<Meal> allMeals;
  final List<Meal> filteredMeals;
  final MealFilter activeFilter;
  final MealSortOption sortOption;
  final bool isLoading;
  final String? error;
  final int activeFilterCount; // computed
}
```

Filter pipeline: `allMeals → applyFilter(activeFilter) → applySort(sortOption) → filteredMeals`

---

## Pagination / Infinite Scroll

Firestore cursor-based pagination:
- Page size: 20 meals
- `startAfterDocument` cursor stored in `CatalogNotifier`
- `ScrollController` triggers `loadMore()` when within 200px of list bottom
- Loading indicator shown at list bottom during fetch

---

## State Management (Riverpod)

```dart
class CatalogNotifier extends AsyncNotifier<CatalogState> {
  Future<void> loadInitial();
  Future<void> loadMore();
  void applyFilter(MealFilter filter);
  void clearFilter();
  void applySort(MealSortOption sort);
  Future<void> search(String query);
  void clearSearch();
}
```

---

## Featured Meals

- Firestore query: `/meals` where `isFeatured == true`, ordered by `featuredOrder asc`
- Displayed as a horizontal `PageView` / carousel at top of CatalogScreen
- Hidden when result set is empty

---

## Recommended Meals

- Fetched from `RecommendationEngine` Cloud Function endpoint: `GET /recommendations/{uid}`
- Returns up to 10 meal IDs; Flutter resolves full meal objects from local cache
- Displayed in a horizontal `ListView` below the Featured section
- Hidden if < 3 results, user is unauthenticated, or request fails (silent failure)

---

## Admin Flows

### Meal Management
- `AdminMealFormScreen`: create/edit form with image picker (1–5 images), category dropdown, dietary tag multi-select, nutritional info fields, availability toggle, featured toggle
- Images uploaded to Firebase Storage: `/meals/{mealId}/{index}.jpg`
- On save: Firestore write → Algolia sync via Cloud Function
- On delete: Firestore soft-delete (set `isAvailable=false`) or hard-delete with Storage cleanup

### Category Management
- `AdminCategoryFormScreen`: name field, image picker, active toggle
- Deactivating a category: Cloud Function sets `isAvailable=false` on all meals in that category

---

## Navigation Flow

```
CatalogScreen
  ├── Search bar → SearchScreen (or inline search results)
  ├── Filter icon → FilterBottomSheet
  ├── Category chip → filtered CatalogScreen
  ├── Featured meal tap → MealDetailScreen
  ├── Recommended meal tap → MealDetailScreen
  ├── Meal card tap → MealDetailScreen
  │     └── "Add to Cart" → CartNotifier.addItem()
  └── Admin FAB (admin only)
        ├── Add Meal → AdminMealFormScreen
        └── Manage Categories → AdminCategoryListScreen → AdminCategoryFormScreen
```

---

## Caching Strategy

```dart
HiveBox<List<Meal>>('catalog_cache')       // first page of meals
HiveBox<List<Category>>('category_cache')  // all active categories
HiveBox<List<Meal>>('featured_cache')      // featured meals
```

Cache TTL: 5 minutes. On app launch: serve cache immediately, refresh in background. On network error: serve stale cache with connectivity banner.

---

## Data Integrity Rules

- Firestore Security Rules: only Admin role (`/users/{uid}.role == 'admin'`) can write to `/meals` and `/categories`
- Price validation: Cloud Function rejects price ≤ 0
- Unique meal name: Firestore transaction checks for existing document with same name before write
- Nutritional values: Cloud Function validates all fields are non-negative numbers

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Network error on load | Show cached data + retry button |
| Search returns no results | "No meals found for '{query}'" empty state |
| Filter returns no results | "No meals match your filters" empty state with clear-filters button |
| Algolia unavailable | Fall back to Firestore prefix search |
| Admin save fails | Show error snackbar, keep form data |
| Image upload fails | Show error, allow retry without re-filling form |
