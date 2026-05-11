import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

/**
 * onOrderCompletedRecommendations
 *
 * Firestore trigger on `/orders/{orderId}` document updates.
 * Fires when the `status` field changes TO `'delivered'` and performs:
 * 1. Increments `popularityScore` by 1 for each meal in the order (atomic)
 * 2. Deletes `/recommendations/{uid}` to invalidate the user's recommendation cache
 *
 * This is separate from the delivery system's `onOrderStatusChanged` trigger.
 * It handles recommendation-specific concerns: popularity scoring and cache invalidation.
 *
 * Validates:
 * - Req 5 AC1: Increment Popularity_Score of each ordered meal by 1
 * - Req 5 AC2: Updated atomically using FieldValue.increment(1)
 * - Req 3 AC1: Recompute recommendations within 60 min of new order (cache invalidation)
 */
export const onOrderCompletedRecommendations = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      functions.logger.warn(
        "onOrderCompletedRecommendations: Missing before/after data"
      );
      return;
    }

    const previousStatus = beforeData.status as string | undefined;
    const newStatus = afterData.status as string | undefined;

    // Only act when status changes TO 'delivered'
    if (newStatus !== "delivered" || previousStatus === "delivered") {
      return;
    }

    const orderId = event.params.orderId;
    const uid = afterData.uid as string | undefined;
    const items = afterData.items as Array<{ mealId?: string }> | undefined;

    const db = admin.firestore();

    functions.logger.info("Order completed — updating popularity scores", {
      orderId,
      uid,
      itemCount: items?.length ?? 0,
    });

    // ── 1. Increment popularityScore for each ordered meal ────────────────
    if (items && Array.isArray(items)) {
      const updatePromises = items
        .filter((item) => item.mealId)
        .map((item) =>
          db.doc(`meals/${item.mealId}`).update({
            popularityScore: admin.firestore.FieldValue.increment(1),
          })
        );

      await Promise.all(updatePromises);

      functions.logger.info("Popularity scores incremented", {
        orderId,
        mealIds: items.filter((item) => item.mealId).map((item) => item.mealId),
      });
    }

    // ── 2. Invalidate user's recommendation cache ─────────────────────────
    if (uid) {
      await db.doc(`recommendations/${uid}`).delete();

      functions.logger.info("Recommendation cache invalidated", {
        orderId,
        uid,
      });
    }
  }
);
