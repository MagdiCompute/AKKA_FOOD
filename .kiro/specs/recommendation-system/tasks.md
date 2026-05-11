# Tasks — Recommendation System

## Task List

- [x] 1. Domain layer — Recommendation entities
  - [x] 1.1 Create `RecommendationResult` entity (mealIds, isPersonalized, computedAt)
  - [x] 1.2 Define `IRecommendationRepository` interface

- [x] 2. Firestore structure
  - [x] 2.1 Create `/recommendations/{uid}` document schema (mealIds, isPersonalized, computedAt)
  - [x] 2.2 Confirm `popularityScore` field exists on `/meals/{mealId}` documents

- [x] 3. Cloud Functions — Recommendation engine
  - [x] 3.1 Implement `computeRecommendations` HTTPS Callable: check cache TTL (60 min), compute personalized or cold-start recommendations, write to `/recommendations/{uid}`
  - [x] 3.2 Implement personalized algorithm: fetch completed orders, build frequency map, apply recency boost (1.5x for last 30 days), exclude last-24h meals, exclude unavailable meals, sort by weighted score, take top 10
  - [x] 3.3 Implement cold-start fallback: query top 10 meals by `popularityScore` where `isAvailable == true`
  - [x] 3.4 Implement fill-up logic: if personalized results < 3, fill remaining slots with popularity-based meals
  - [x] 3.5 Implement `onOrderCompleted` trigger: increment `popularityScore` for each ordered meal, delete `/recommendations/{uid}` to invalidate cache
  - [x] 3.6 Implement `refreshPopularityRankings` scheduled function (every hour): write top 50 meals to `/analytics/popularMeals`
  - [x] 3.7 Write unit tests for recommendation scoring algorithm

- [x] 4. Data layer — RecommendationRepository
  - [x] 4.1 Implement `CloudFunctionRecommendationDataSource`: call `computeRecommendations` Cloud Function
  - [x] 4.2 Implement `FirestoreRecommendationCache`: read `/recommendations/{uid}` for TTL check
  - [x] 4.3 Implement `RecommendationRepository` composing both sources

- [x] 5. State management — RecommendationNotifier
  - [x] 5.1 Implement `RecommendationNotifier` (Riverpod): loadRecommendations, resolve mealIds to Meal objects from catalog cache, filter unavailable meals client-side
  - [x] 5.2 Implement silent failure: on error, emit empty list (no error shown to user)
  - [x] 5.3 Write unit tests for RecommendationNotifier

- [x] 6. Presentation layer — Recommended section
  - [x] 6.1 Implement `RecommendedSection` widget in `CatalogScreen`: horizontal ListView of MealCards
  - [x] 6.2 Hide section when result count < 3 or user is unauthenticated
  - [x] 6.3 Show "Recommended for You" header with personalized indicator
  - [x] 6.4 Implement tap → navigate to MealDetailScreen

- [x] 7. Popularity score maintenance
  - [x] 7.1 Verify `onOrderCompleted` Cloud Function increments `popularityScore` atomically using `FieldValue.increment(1)`
  - [x] 7.2 Implement Firestore Security Rules: `popularityScore` writable only by Cloud Functions

- [x] 8. Integration testing
  - [x] 8.1 Write integration test: user with ≥ 3 orders sees personalized recommendations
  - [x] 8.2 Write integration test: new user sees popularity-based recommendations
  - [x] 8.3 Write integration test: recommendations refresh after new order (cache invalidated)
  - [x] 8.4 Write integration test: unavailable meal excluded from recommendations
  - [x] 8.5 Write integration test: recommendation engine error → section hidden silently
