# Tasks — Recommendation System

## Task List

- [ ] 1. Domain layer — Recommendation entities
  - [ ] 1.1 Create `RecommendationResult` entity (mealIds, isPersonalized, computedAt)
  - [ ] 1.2 Define `IRecommendationRepository` interface

- [ ] 2. Firestore structure
  - [ ] 2.1 Create `/recommendations/{uid}` document schema (mealIds, isPersonalized, computedAt)
  - [ ] 2.2 Confirm `popularityScore` field exists on `/meals/{mealId}` documents

- [ ] 3. Cloud Functions — Recommendation engine
  - [ ] 3.1 Implement `computeRecommendations` HTTPS Callable: check cache TTL (60 min), compute personalized or cold-start recommendations, write to `/recommendations/{uid}`
  - [ ] 3.2 Implement personalized algorithm: fetch completed orders, build frequency map, apply recency boost (1.5x for last 30 days), exclude last-24h meals, exclude unavailable meals, sort by weighted score, take top 10
  - [ ] 3.3 Implement cold-start fallback: query top 10 meals by `popularityScore` where `isAvailable == true`
  - [ ] 3.4 Implement fill-up logic: if personalized results < 3, fill remaining slots with popularity-based meals
  - [ ] 3.5 Implement `onOrderCompleted` trigger: increment `popularityScore` for each ordered meal, delete `/recommendations/{uid}` to invalidate cache
  - [ ] 3.6 Implement `refreshPopularityRankings` scheduled function (every hour): write top 50 meals to `/analytics/popularMeals`
  - [ ] 3.7 Write unit tests for recommendation scoring algorithm

- [ ] 4. Data layer — RecommendationRepository
  - [ ] 4.1 Implement `CloudFunctionRecommendationDataSource`: call `computeRecommendations` Cloud Function
  - [ ] 4.2 Implement `FirestoreRecommendationCache`: read `/recommendations/{uid}` for TTL check
  - [ ] 4.3 Implement `RecommendationRepository` composing both sources

- [ ] 5. State management — RecommendationNotifier
  - [ ] 5.1 Implement `RecommendationNotifier` (Riverpod): loadRecommendations, resolve mealIds to Meal objects from catalog cache, filter unavailable meals client-side
  - [ ] 5.2 Implement silent failure: on error, emit empty list (no error shown to user)
  - [ ] 5.3 Write unit tests for RecommendationNotifier

- [ ] 6. Presentation layer — Recommended section
  - [ ] 6.1 Implement `RecommendedSection` widget in `CatalogScreen`: horizontal ListView of MealCards
  - [ ] 6.2 Hide section when result count < 3 or user is unauthenticated
  - [ ] 6.3 Show "Recommended for You" header with personalized indicator
  - [ ] 6.4 Implement tap → navigate to MealDetailScreen

- [ ] 7. Popularity score maintenance
  - [ ] 7.1 Verify `onOrderCompleted` Cloud Function increments `popularityScore` atomically using `FieldValue.increment(1)`
  - [ ] 7.2 Implement Firestore Security Rules: `popularityScore` writable only by Cloud Functions

- [ ] 8. Integration testing
  - [ ] 8.1 Write integration test: user with ≥ 3 orders sees personalized recommendations
  - [ ] 8.2 Write integration test: new user sees popularity-based recommendations
  - [ ] 8.3 Write integration test: recommendations refresh after new order (cache invalidated)
  - [ ] 8.4 Write integration test: unavailable meal excluded from recommendations
  - [ ] 8.5 Write integration test: recommendation engine error → section hidden silently
