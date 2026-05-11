import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as functions from "firebase-functions";

const CACHE_TTL_MS = 60 * 60 * 1000; // 60 minutes

/**
 * Fetches completed (delivered) orders for a given user.
 * Returns an array of order documents with their data.
 */
export async function getCompletedOrders(uid: string) {
  const db = admin.firestore();
  const ordersSnap = await db
    .collection("orders")
    .where("uid", "==", uid)
    .where("status", "==", "delivered")
    .get();

  return ordersSnap.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

/**
 * Computes the weighted score for a single meal across all orders.
 * - Each order containing the meal contributes to the score
 * - Orders in the last 30 days get a 1.5x recency boost
 * - Orders in the last 24 hours are excluded (to encourage variety)
 *
 * Validates: Requirements 1.2, 1.4
 */
export function weightedScore(
  mealId: string,
  orders: Array<Record<string, unknown>>
): number {
  const now = Date.now();
  const thirtyDaysAgo = now - 30 * 24 * 60 * 60 * 1000;
  const oneDayAgo = now - 24 * 60 * 60 * 1000;

  let score = 0;
  for (const order of orders) {
    const items = order.items as Array<{ mealId?: string }> | undefined;
    if (!items || !Array.isArray(items)) continue;

    const hasMeal = items.some((item) => item.mealId === mealId);
    if (!hasMeal) continue;

    // Get completedAt timestamp in milliseconds
    const completedAt = getCompletedAtMillis(order);
    if (completedAt === null) continue;

    // Exclude orders from the last 24 hours
    if (completedAt > oneDayAgo) continue;

    // Apply recency boost for orders in the last 30 days
    const recencyBoost = completedAt > thirtyDaysAgo ? 1.5 : 1.0;
    score += recencyBoost;
  }
  return score;
}

/**
 * Extracts the completedAt timestamp in milliseconds from an order document.
 * Handles both Firestore Timestamp objects and plain numbers.
 */
function getCompletedAtMillis(order: Record<string, unknown>): number | null {
  const completedAt = order.completedAt;
  if (!completedAt) return null;

  // Firestore Timestamp has a toMillis() method
  if (typeof (completedAt as { toMillis?: () => number }).toMillis === "function") {
    return (completedAt as { toMillis: () => number }).toMillis();
  }

  // If it's already a number (milliseconds)
  if (typeof completedAt === "number") {
    return completedAt;
  }

  // If it has _seconds (Firestore Timestamp serialized form)
  if (typeof (completedAt as { _seconds?: number })._seconds === "number") {
    return (completedAt as { _seconds: number })._seconds * 1000;
  }

  return null;
}

/**
 * Computes personalized meal recommendations based on order history.
 *
 * Algorithm:
 * 1. Build a weighted score map from all orders (frequency + recency boost)
 * 2. Exclude meals ordered in the last 24 hours (score will be 0)
 * 3. Check meal availability by reading /meals/{mealId} documents
 * 4. Sort by weighted score descending
 * 5. Return top 10 meal IDs
 *
 * Validates: Requirements 1.1, 1.2, 1.3, 1.4
 *
 * @param orders - Array of completed order documents
 * @returns Array of up to 10 meal IDs sorted by weighted score
 */
export async function computePersonalized(
  orders: Array<Record<string, unknown>>
): Promise<string[]> {
  const db = admin.firestore();

  // Step 1 & 2: Build weighted score map (excludes last-24h meals via scoring)
  const scoreMap = new Map<string, number>();

  for (const order of orders) {
    const items = order.items as Array<{ mealId?: string }> | undefined;
    if (!items || !Array.isArray(items)) continue;

    for (const item of items) {
      if (!item.mealId) continue;
      if (!scoreMap.has(item.mealId)) {
        scoreMap.set(item.mealId, 0);
      }
    }
  }

  // Calculate weighted score for each unique meal
  const mealIds = Array.from(scoreMap.keys());
  for (const mealId of mealIds) {
    scoreMap.set(mealId, weightedScore(mealId, orders));
  }

  // Remove meals with score 0 (only ordered in last 24h or no valid orders)
  const entries = Array.from(scoreMap.entries());
  for (const [mealId, score] of entries) {
    if (score === 0) {
      scoreMap.delete(mealId);
    }
  }

  // Step 3: Check meal availability by reading /meals/{mealId} documents
  const candidateMealIds = Array.from(scoreMap.keys());

  if (candidateMealIds.length === 0) {
    return [];
  }

  // Batch-read meal documents to check availability
  const mealRefs = candidateMealIds.map((id) => db.doc(`meals/${id}`));
  const mealDocs = await db.getAll(...mealRefs);

  const availableMealIds = new Set<string>();
  for (const doc of mealDocs) {
    if (doc.exists) {
      const data = doc.data();
      if (data?.isAvailable === true) {
        availableMealIds.add(doc.id);
      }
    }
  }

  // Filter to only available meals
  const availableCandidates = candidateMealIds.filter((id) =>
    availableMealIds.has(id)
  );

  // Step 4: Sort by weighted score descending
  availableCandidates.sort((a, b) => {
    const scoreA = scoreMap.get(a) || 0;
    const scoreB = scoreMap.get(b) || 0;
    return scoreB - scoreA;
  });

  // Step 5: Return top 10
  return availableCandidates.slice(0, 10);
}

/**
 * Returns popular meals for cold-start users (< 3 orders).
 * Queries the top 10 available meals ordered by popularityScore descending.
 *
 * Validates: Requirements 2.1, 2.2
 *
 * @returns Array of up to 10 meal IDs sorted by popularity score
 */
export async function getPopularMeals(): Promise<string[]> {
  const db = admin.firestore();
  const mealsSnap = await db
    .collection("meals")
    .where("isAvailable", "==", true)
    .orderBy("popularityScore", "desc")
    .limit(10)
    .get();

  return mealsSnap.docs.map((doc) => doc.id);
}

/**
 * computeRecommendations — HTTPS Callable Cloud Function
 *
 * Computes personalized or cold-start meal recommendations for the authenticated user.
 *
 * Steps:
 * 1. Validate caller's auth token
 * 2. Check cache at /recommendations/{uid} — if fresh (< 60 min), return cached data
 * 3. Fetch completed orders for the user
 * 4. If >= 3 orders: compute personalized recommendations
 * 5. If < 3 orders: return popularity-based recommendations (cold start)
 * 6. Write result to /recommendations/{uid} with serverTimestamp
 * 7. Return { mealIds, isPersonalized }
 *
 * Validates:
 * - Req 1 AC1: Return up to 10 personalized meals for users with >= 3 orders
 * - Req 2 AC1: Return top 10 by popularity for users with < 3 orders
 * - Req 3 AC2: Cache with 60-minute TTL
 */
export const computeRecommendations = onCall(async (request) => {
  // ── Step 1: Validate authentication ─────────────────────────────────────
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to get recommendations."
    );
  }

  const uid = request.auth.uid;
  const db = admin.firestore();

  // ── Step 2: Check cache ─────────────────────────────────────────────────
  const cacheRef = db.doc(`recommendations/${uid}`);
  const cacheDoc = await cacheRef.get();

  if (cacheDoc.exists) {
    const cacheData = cacheDoc.data();
    if (cacheData?.computedAt) {
      const computedAtMillis = cacheData.computedAt.toMillis();
      const age = Date.now() - computedAtMillis;

      if (age < CACHE_TTL_MS) {
        functions.logger.info("Serving cached recommendations", {
          uid,
          ageMinutes: Math.round(age / 60000),
        });
        return {
          mealIds: cacheData.mealIds,
          isPersonalized: cacheData.isPersonalized,
        };
      }
    }
  }

  // ── Step 3: Fetch completed orders ──────────────────────────────────────
  const orders = await getCompletedOrders(uid);

  functions.logger.info("Computing recommendations", {
    uid,
    completedOrders: orders.length,
    isPersonalized: orders.length >= 3,
  });

  // ── Step 4/5: Compute recommendations ───────────────────────────────────
  let mealIds: string[];

  if (orders.length >= 3) {
    mealIds = await computePersonalized(orders);

    // Fill-up logic: if personalized results < 3, fill remaining slots
    // with popularity-based meals up to 10 total (Req 1 AC5)
    if (mealIds.length < 3) {
      const popularMeals = await getPopularMeals();
      const existingIds = new Set(mealIds);
      const fillMeals = popularMeals.filter((id) => !existingIds.has(id));
      const slotsRemaining = 10 - mealIds.length;
      mealIds = [...mealIds, ...fillMeals.slice(0, slotsRemaining)];
    }
  } else {
    mealIds = await getPopularMeals();
  }

  const isPersonalized = orders.length >= 3;

  // ── Step 6: Cache result ────────────────────────────────────────────────
  await cacheRef.set({
    mealIds,
    isPersonalized,
    computedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  functions.logger.info("Recommendations computed and cached", {
    uid,
    mealCount: mealIds.length,
    isPersonalized,
  });

  // ── Step 7: Return result ───────────────────────────────────────────────
  return { mealIds, isPersonalized };
});
