# Tasks — Meal Catalog

## Task List

- [x] 1. Domain layer — Catalog entities and interfaces
  - [x] 1.1 Create `Meal` entity (id, name, description, price, categoryId, imageUrls, isAvailable, isFeatured, featuredOrder, nutritionalInfo, dietaryTags, popularityScore, createdAt, updatedAt)
  - [x] 1.2 Create `Category` entity (id, name, imageUrl, isActive, createdAt)
  - [x] 1.3 Create `NutritionalInfo` value object (calories, proteins, carbohydrates, fats)
  - [x] 1.4 Create `MealFilter` and `MealSortOption` models
  - [x] 1.5 Define `IMealRepository` and `ICategoryRepository` interfaces

- [x] 2. Data layer — Firestore data sources
  - [x] 2.1 Implement `FirestoreMealDataSource`: paginated query (page size 20), cursor-based pagination
  - [x] 2.2 Implement `FirestoreCategoryDataSource`: fetch all active categories
  - [x] 2.3 Implement `FirestoreFeaturedDataSource`: fetch featured meals ordered by `featuredOrder`
  - [x] 2.4 Implement `MealRepository` and `CategoryRepository` composing Firestore sources

- [x] 3. Data layer — Search
  - [x] 3.1 Set up Algolia index for meals (searchable: name, description, dietaryTags; filterable: categoryId, isAvailable, price)
  - [x] 3.2 Implement `AlgoliaSearchDataSource` using `algolia` Flutter package
  - [x] 3.3 Implement Firestore → Algolia sync Cloud Function (onCreate, onUpdate, onDelete for `/meals`)
  - [x] 3.4 Implement fallback Firestore prefix search when Algolia is unavailable

- [x] 4. Data layer — Local cache
  - [x] 4.1 Set up Hive boxes: `catalog_cache`, `category_cache`, `featured_cache`
  - [x] 4.2 Implement 5-minute TTL cache with stale-while-revalidate in `MealRepository`

- [x] 5. State management — CatalogNotifier
  - [x] 5.1 Implement `CatalogNotifier` (Riverpod): loadInitial, loadMore, applyFilter, clearFilter, applySort, search, clearSearch
  - [x] 5.2 Implement filter pipeline: `allMeals → applyFilter → applySort → filteredMeals`
  - [x] 5.3 Implement active filter count computation
  - [x] 5.4 Implement `SearchNotifier` with 300ms debounce
  - [x] 5.5 Write unit tests for filter and sort logic

- [x] 6. Presentation layer — Catalog screens
  - [x] 6.1 Implement `CatalogScreen`: category chips row, featured carousel, recommended section, meal grid/list
  - [x] 6.2 Implement `MealCard` widget: name, image, price, availability badge
  - [x] 6.3 Implement `CategoryChip` widget: name + icon, selected state
  - [x] 6.4 Implement `FeaturedBanner` carousel (PageView with auto-scroll)
  - [x] 6.5 Implement `RecommendedSection` horizontal ListView (hidden when < 3 items)
  - [x] 6.6 Implement infinite scroll with `ScrollController` and loading indicator
  - [x] 6.7 Implement `MealDetailScreen`: image gallery (swipe), nutritional info, dietary tags, add-to-cart button
  - [x] 6.8 Implement `FilterBottomSheet`: category multi-select, price range slider, dietary tag chips, availability toggle
  - [x] 6.9 Implement active filter count badge on filter icon
  - [x] 6.10 Implement sort dropdown/bottom sheet

- [x] 7. Admin meal management screens
  - [x] 7.1 Implement `AdminMealListScreen`: all meals list with availability toggle
  - [x] 7.2 Implement `AdminMealFormScreen`: create/edit form with image picker (1–5 images), all fields, featured toggle
  - [x] 7.3 Implement `AdminCategoryListScreen` and `AdminCategoryFormScreen`
  - [x] 7.4 Implement image upload to Firebase Storage: `/meals/{mealId}/{index}.jpg`

- [x] 8. Cloud Functions — Catalog
  - [x] 8.1 Implement `onCategoryDeactivated`: batch-set `isAvailable=false` on all meals in category
  - [x] 8.2 Implement meal price and name uniqueness validation in Cloud Function
  - [x] 8.3 Implement nutritional info validation (non-negative values)

- [x] 9. Firestore Security Rules
  - [x] 9.1 Write rules: `/meals` and `/categories` readable by all authenticated users, writable only by admin role
  - [x] 9.2 Write Firebase Storage rules: `/meals/**` writable by admin, publicly readable

- [x] 10. Integration testing
  - [x] 10.1 Write integration test: browse catalog, apply category filter, clear filter
  - [x] 10.2 Write integration test: search meals with debounce
  - [x] 10.3 Write integration test: sort by price ascending/descending
  - [x] 10.4 Write integration test: admin create meal → appears in catalog
