# Tasks — Meal Catalog

## Task List

- [ ] 1. Domain layer — Catalog entities and interfaces
  - [ ] 1.1 Create `Meal` entity (id, name, description, price, categoryId, imageUrls, isAvailable, isFeatured, featuredOrder, nutritionalInfo, dietaryTags, popularityScore, createdAt, updatedAt)
  - [ ] 1.2 Create `Category` entity (id, name, imageUrl, isActive, createdAt)
  - [ ] 1.3 Create `NutritionalInfo` value object (calories, proteins, carbohydrates, fats)
  - [ ] 1.4 Create `MealFilter` and `MealSortOption` models
  - [ ] 1.5 Define `IMealRepository` and `ICategoryRepository` interfaces

- [ ] 2. Data layer — Firestore data sources
  - [ ] 2.1 Implement `FirestoreMealDataSource`: paginated query (page size 20), cursor-based pagination
  - [ ] 2.2 Implement `FirestoreCategoryDataSource`: fetch all active categories
  - [ ] 2.3 Implement `FirestoreFeaturedDataSource`: fetch featured meals ordered by `featuredOrder`
  - [ ] 2.4 Implement `MealRepository` and `CategoryRepository` composing Firestore sources

- [ ] 3. Data layer — Search
  - [ ] 3.1 Set up Algolia index for meals (searchable: name, description, dietaryTags; filterable: categoryId, isAvailable, price)
  - [ ] 3.2 Implement `AlgoliaSearchDataSource` using `algolia` Flutter package
  - [ ] 3.3 Implement Firestore → Algolia sync Cloud Function (onCreate, onUpdate, onDelete for `/meals`)
  - [ ] 3.4 Implement fallback Firestore prefix search when Algolia is unavailable

- [ ] 4. Data layer — Local cache
  - [ ] 4.1 Set up Hive boxes: `catalog_cache`, `category_cache`, `featured_cache`
  - [ ] 4.2 Implement 5-minute TTL cache with stale-while-revalidate in `MealRepository`

- [ ] 5. State management — CatalogNotifier
  - [ ] 5.1 Implement `CatalogNotifier` (Riverpod): loadInitial, loadMore, applyFilter, clearFilter, applySort, search, clearSearch
  - [ ] 5.2 Implement filter pipeline: `allMeals → applyFilter → applySort → filteredMeals`
  - [ ] 5.3 Implement active filter count computation
  - [ ] 5.4 Implement `SearchNotifier` with 300ms debounce
  - [ ] 5.5 Write unit tests for filter and sort logic

- [ ] 6. Presentation layer — Catalog screens
  - [ ] 6.1 Implement `CatalogScreen`: category chips row, featured carousel, recommended section, meal grid/list
  - [ ] 6.2 Implement `MealCard` widget: name, image, price, availability badge
  - [ ] 6.3 Implement `CategoryChip` widget: name + icon, selected state
  - [ ] 6.4 Implement `FeaturedBanner` carousel (PageView with auto-scroll)
  - [ ] 6.5 Implement `RecommendedSection` horizontal ListView (hidden when < 3 items)
  - [ ] 6.6 Implement infinite scroll with `ScrollController` and loading indicator
  - [ ] 6.7 Implement `MealDetailScreen`: image gallery (swipe), nutritional info, dietary tags, add-to-cart button
  - [ ] 6.8 Implement `FilterBottomSheet`: category multi-select, price range slider, dietary tag chips, availability toggle
  - [ ] 6.9 Implement active filter count badge on filter icon
  - [ ] 6.10 Implement sort dropdown/bottom sheet

- [ ] 7. Admin meal management screens
  - [ ] 7.1 Implement `AdminMealListScreen`: all meals list with availability toggle
  - [ ] 7.2 Implement `AdminMealFormScreen`: create/edit form with image picker (1–5 images), all fields, featured toggle
  - [ ] 7.3 Implement `AdminCategoryListScreen` and `AdminCategoryFormScreen`
  - [ ] 7.4 Implement image upload to Firebase Storage: `/meals/{mealId}/{index}.jpg`

- [ ] 8. Cloud Functions — Catalog
  - [ ] 8.1 Implement `onCategoryDeactivated`: batch-set `isAvailable=false` on all meals in category
  - [ ] 8.2 Implement meal price and name uniqueness validation in Cloud Function
  - [ ] 8.3 Implement nutritional info validation (non-negative values)

- [ ] 9. Firestore Security Rules
  - [ ] 9.1 Write rules: `/meals` and `/categories` readable by all authenticated users, writable only by admin role
  - [ ] 9.2 Write Firebase Storage rules: `/meals/**` writable by admin, publicly readable

- [ ] 10. Integration testing
  - [ ] 10.1 Write integration test: browse catalog, apply category filter, clear filter
  - [ ] 10.2 Write integration test: search meals with debounce
  - [ ] 10.3 Write integration test: sort by price ascending/descending
  - [ ] 10.4 Write integration test: admin create meal → appears in catalog
