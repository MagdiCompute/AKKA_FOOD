import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";

/**
 * refreshPopularityRankings — Scheduled Cloud Function (every hour)
 *
 * Queries the top 50 meals by popularityScore and writes them to
 * `/analytics/popularMeals` for fast reads by the admin dashboard
 * and cold-start recommendation logic.
 *
 * Validates:
 * - Req 5 AC3: Recompute global popularity rankings at least once per hour
 */
export const refreshPopularityRankings = onSchedule("every 60 minutes", async () => {
  const db = admin.firestore();

  // Query top 50 meals ordered by popularityScore descending
  const topMealsSnap = await db
    .collection("meals")
    .orderBy("popularityScore", "desc")
    .limit(50)
    .get();

  if (topMealsSnap.empty) {
    functions.logger.info("No meals found for popularity rankings", {
      timestamp: new Date().toISOString(),
    });
    return;
  }

  // Build the ranked list with meal IDs, names, and scores
  const rankedMeals = topMealsSnap.docs.map((doc) => {
    const data = doc.data();
    return {
      mealId: doc.id,
      name: data.name || null,
      popularityScore: data.popularityScore || 0,
    };
  });

  const mealIds = rankedMeals.map((m) => m.mealId);

  // Write to /analytics/popularMeals for fast reads
  await db.doc("analytics/popularMeals").set({
    mealIds,
    rankedMeals,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  functions.logger.info("Popularity rankings refreshed", {
    mealCount: mealIds.length,
    topMealId: mealIds[0] || null,
    timestamp: new Date().toISOString(),
  });
});
