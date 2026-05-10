# Design Document — Recommendation System

## Overview

The Recommendation System is a Cloud Function-based engine that computes personalized meal suggestions from purchase history. Results are cached in Firestore per user with a 60-minute TTL. The Flutter app fetches recommendations on catalog load and displays them in a dedicated section.

---

## Architecture

```
Presentation Layer
  └── Widget: RecommendedSection (in CatalogScreen)
  └── State: RecommendationNotifier (Riverpod)

Domain Layer
  └── Entities: Recommendation, RecommendationResult
  └── Use Cases: GetRecommendationsUseCase

Data Layer
  └── RecommendationRepository
  └── CloudFunctionRecommendationDataSource
  └── FirestoreRecommendationCache
```

---

## Data Models

### RecommendationResult
```dart
class RecommendationResult {
  final List<String> mealIds;   // ordered by relevance score desc
  final bool isPersonalized;    // false = cold-start popularity-based
  final DateTime computedAt;
}
```

---

## Firestore Structure

```
/recommendations/{uid}
  - mealIds: string[]          // up to 10 meal IDs, ordered by score
  - isPersonalized: bool
  - computedAt: timestamp      // used for TTL check (60 min)

/meals/{mealId}
  - popularityScore: number    // incremented on each completed order
```

---

## Recommendation Algorithm

### Personalized (≥ 3 orders)

```javascript
// 1. Fetch user's completed orders from /orders where uid == uid and status == 'delivered'
// 2. Build meal frequency map: { mealId: count }
// 3. Apply recency boost: orders in last 30 days get 1.5x weight
// 4. Exclude meals ordered in last 24 hours
// 5. Exclude unavailable meals
// 6. Sort by weighted score desc, take top 10
// 7. If < 3 results, fill remaining slots with top popularity-based meals
```

### Cold Start (< 3 orders)

```javascript
// Query /meals where isAvailable == true, order by popularityScore desc, limit 10
```

---

## Cloud Functions

### `computeRecommendations` (HTTPS Callable)
Called by Flutter app on catalog load if cache is stale (> 60 min) or missing.

```javascript
exports.computeRecommendations = functions.https.onCall(async (data, context) => {
  const uid = context.auth.uid;
  
  // Check cache
  const cacheDoc = await db.doc(`recommendations/${uid}`).get();
  if (cacheDoc.exists) {
    const age = Date.now() - cacheDoc.data().computedAt.toMillis();
    if (age < 60 * 60 * 1000) return cacheDoc.data(); // serve cache
  }
  
  // Compute
  const orders = await getCompletedOrders(uid);
  const mealIds = orders.length >= 3
    ? computePersonalized(orders)
    : await getPopularMeals();
  
  // Cache result
  await db.doc(`recommendations/${uid}`).set({
    mealIds,
    isPersonalized: orders.length >= 3,
    computedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  return { mealIds, isPersonalized: orders.length >= 3 };
});
```

### `onOrderCompleted` (Firestore trigger — also updates popularity)
```javascript
// For each meal in the completed order:
await db.doc(`meals/${mealId}`).update({
  popularityScore: admin.firestore.FieldValue.increment(1)
});

// Invalidate user's recommendation cache
await db.doc(`recommendations/${uid}`).delete();
// Next catalog open will trigger fresh computation
```

### `refreshPopularityRankings` (Scheduled: every hour)
```javascript
// Query top 50 meals by popularityScore
// Write to /analytics/popularMeals for fast reads
```

---

## State Management (Riverpod)

```dart
class RecommendationNotifier extends AsyncNotifier<List<Meal>> {
  Future<void> loadRecommendations() async {
    // 1. Call computeRecommendations Cloud Function
    // 2. Resolve mealIds to full Meal objects from local catalog cache
    // 3. Filter out unavailable meals client-side
    state = AsyncData(resolvedMeals);
  }
}
```

Meal objects are resolved from the local Hive catalog cache to avoid extra Firestore reads.

---

## Availability Filter (Client-Side)

After receiving `mealIds` from the Cloud Function, the Flutter app filters against the local catalog cache:

```dart
final availableMeals = mealIds
    .map((id) => catalogCache.getMeal(id))
    .whereType<Meal>()
    .where((m) => m.isAvailable)
    .take(10)
    .toList();
```

If `availableMeals.length < 3`, the Recommended section is hidden.

---

## Scoring Formula

```javascript
function weightedScore(mealId, orders) {
  const now = Date.now();
  const thirtyDaysAgo = now - 30 * 24 * 60 * 60 * 1000;
  const oneDayAgo = now - 24 * 60 * 60 * 1000;

  let score = 0;
  for (const order of orders) {
    if (!order.mealIds.includes(mealId)) continue;
    if (order.completedAt > oneDayAgo) continue; // exclude recent 24h
    const recencyBoost = order.completedAt > thirtyDaysAgo ? 1.5 : 1.0;
    score += recencyBoost;
  }
  return score;
}
```

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Cloud Function timeout | Hide Recommended section silently |
| Cache miss + network error | Hide Recommended section silently |
| All recommended meals unavailable | Hide Recommended section |
| < 3 results after filtering | Fill with popularity-based meals |
| User not authenticated | Hide Recommended section |
