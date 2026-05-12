import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { PubSub } from "@google-cloud/pubsub";

/**
 * onOrderCompletedLeaderboard
 *
 * Firestore trigger on `/orders/{orderId}` document updates.
 * Fires when the `status` field changes TO `'delivered'` or `'completed'`
 * (and was NOT already that status) and performs:
 *
 * 1. Atomically increments `allTimeScore`, `monthlyScore`, `weeklyScore` by 1
 *    in `/userScores/{uid}` using a Firestore transaction
 * 2. Sets `leaderboardVisible` to `true` if the document doesn't exist yet (merge)
 * 3. Invalidates the user's recommendation cache
 * 4. Triggers leaderboard rebuild via Pub/Sub message to `rebuild-leaderboard` topic
 *
 * Idempotency: Does NOT increment if the previous status was already
 * 'delivered' or 'completed' (prevents double-counting on retries).
 *
 * Validates:
 * - Req 3 AC1: Count only orders with status `delivered` or `completed`
 * - Req 3 AC2: Do NOT count cancelled or refunded orders
 * - Req 3 AC3: Update User's Score within 60 seconds of status change
 * - Req 1 AC5: Rankings update within 60 seconds of a new completed order
 */
export const onOrderCompletedLeaderboard = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      functions.logger.warn(
        "onOrderCompletedLeaderboard: Missing before/after data"
      );
      return;
    }

    const previousStatus = beforeData.status as string | undefined;
    const newStatus = afterData.status as string | undefined;

    // Only proceed if status changed to 'delivered' or 'completed'
    const completedStatuses = ["delivered", "completed"];
    if (!newStatus || !completedStatuses.includes(newStatus)) {
      return;
    }

    // Idempotency: don't increment if previous status was already delivered/completed
    if (previousStatus && completedStatuses.includes(previousStatus)) {
      return;
    }

    const orderId = event.params.orderId;
    const uid = afterData.uid as string | undefined;

    if (!uid) {
      functions.logger.error(
        "onOrderCompletedLeaderboard: Missing uid on order",
        {
          orderId,
          timestamp: new Date().toISOString(),
        }
      );
      return;
    }

    const db = admin.firestore();

    functions.logger.info(
      "Order completed — updating leaderboard scores",
      {
        orderId,
        uid,
        newStatus,
        previousStatus,
      }
    );

    // ── 1. Atomically increment userScores ────────────────────────────────
    try {
      await db.runTransaction(async (t) => {
        const scoreRef = db.doc(`userScores/${uid}`);
        const scoreSnap = await t.get(scoreRef);
        const scores = scoreSnap.data() || {};

        t.set(
          scoreRef,
          {
            allTimeScore: (scores.allTimeScore || 0) + 1,
            monthlyScore: (scores.monthlyScore || 0) + 1,
            weeklyScore: (scores.weeklyScore || 0) + 1,
            leaderboardVisible: scores.leaderboardVisible ?? true,
          },
          { merge: true }
        );
      });

      functions.logger.info("Leaderboard scores incremented", {
        orderId,
        uid,
      });
    } catch (error: unknown) {
      functions.logger.error("Failed to increment leaderboard scores", {
        orderId,
        uid,
        error: error instanceof Error ? error.message : String(error),
        timestamp: new Date().toISOString(),
      });
      throw error; // Re-throw to trigger Cloud Functions retry
    }

    // ── 2. Invalidate recommendation cache ────────────────────────────────
    try {
      await db.doc(`recommendations/${uid}`).delete();
      functions.logger.info("Recommendation cache invalidated for leaderboard", {
        orderId,
        uid,
      });
    } catch (error: unknown) {
      // Non-critical: log but don't fail the function
      functions.logger.warn("Failed to invalidate recommendation cache", {
        orderId,
        uid,
        error: error instanceof Error ? error.message : String(error),
      });
    }

    // ── 3. Trigger leaderboard rebuild via Pub/Sub ──────────────────────────
    try {
      const pubsub = new PubSub();
      const topic = pubsub.topic("rebuild-leaderboard");
      await topic.publishMessage({
        json: { uid, orderId, timestamp: new Date().toISOString() },
      });

      functions.logger.info("Published rebuild-leaderboard message", {
        orderId,
        uid,
      });
    } catch (error: unknown) {
      // Non-critical: log but don't fail the function
      functions.logger.warn("Failed to publish rebuild-leaderboard message", {
        orderId,
        uid,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
);
