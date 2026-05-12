import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import { PubSub } from "@google-cloud/pubsub";

/**
 * resetMonthlyScores — Scheduled Cloud Function
 *
 * Runs on the 1st of each month at 00:00 UTC (cron: `0 0 1 * *`).
 * Resets all users' monthly scores to zero and cleans up the previous month's
 * leaderboard document.
 *
 * Steps:
 * 1. Query ALL documents in `/userScores` collection
 * 2. Batch-update `monthlyScore = 0` for all documents (max 500 per batch)
 * 3. Delete the previous month's leaderboard document: `/leaderboard/monthly_{YYYY_MM}`
 * 4. Trigger a leaderboard rebuild via Pub/Sub to update the new month's leaderboard
 *
 * Validates:
 * - Req 3 AC4: Monthly period counts only orders completed within the current
 *   calendar month
 */
export const resetMonthlyScores = onSchedule("0 0 1 * *", async () => {
  const db = admin.firestore();
  const now = new Date();

  functions.logger.info("Starting monthly score reset", {
    timestamp: now.toISOString(),
  });

  // ── 1. Batch-reset monthlyScore = 0 for all userScores documents ────────
  let totalReset = 0;
  let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;

  // Paginate through all userScores documents
  while (true) {
    let query: admin.firestore.Query = db
      .collection("userScores")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(500);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      break;
    }

    // Batch update this page of documents
    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.update(doc.ref, { monthlyScore: 0 });
    }
    await batch.commit();

    totalReset += snapshot.docs.length;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    functions.logger.info("Monthly score reset batch committed", {
      batchSize: snapshot.docs.length,
      totalReset,
      timestamp: new Date().toISOString(),
    });

    // If we got fewer than 500 docs, we've reached the end
    if (snapshot.docs.length < 500) {
      break;
    }
  }

  functions.logger.info("All monthly scores reset to zero", {
    totalReset,
    timestamp: new Date().toISOString(),
  });

  // ── 2. Delete previous month's leaderboard document ─────────────────────
  try {
    const prevMonthDocId = getPreviousMonthDocId(now);
    await db.doc(`leaderboard/${prevMonthDocId}`).delete();

    functions.logger.info("Deleted previous month leaderboard document", {
      docId: prevMonthDocId,
      timestamp: new Date().toISOString(),
    });
  } catch (error: unknown) {
    // Non-critical: log but don't fail the function
    functions.logger.warn("Failed to delete previous month leaderboard document", {
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString(),
    });
  }

  // ── 3. Trigger leaderboard rebuild via Pub/Sub ──────────────────────────
  try {
    const pubsub = new PubSub();
    const topic = pubsub.topic("rebuild-leaderboard");
    await topic.publishMessage({
      json: {
        reason: "monthly_reset",
        timestamp: now.toISOString(),
      },
    });

    functions.logger.info("Published rebuild-leaderboard message after monthly reset", {
      timestamp: new Date().toISOString(),
    });
  } catch (error: unknown) {
    functions.logger.warn("Failed to publish rebuild-leaderboard message", {
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString(),
    });
  }

  functions.logger.info("Monthly score reset complete", {
    totalReset,
    timestamp: new Date().toISOString(),
  });
});

/**
 * Computes the previous month's leaderboard document ID.
 *
 * Since this function runs on the 1st of the new month, the previous month
 * is simply one month before the current date.
 *
 * @returns Document ID in the format `monthly_YYYY_MM`
 */
export function getPreviousMonthDocId(date: Date): string {
  const prevMonth = new Date(date.getTime());
  prevMonth.setUTCMonth(prevMonth.getUTCMonth() - 1);

  const year = prevMonth.getUTCFullYear();
  const month = (prevMonth.getUTCMonth() + 1).toString().padStart(2, "0");
  return `monthly_${year}_${month}`;
}
