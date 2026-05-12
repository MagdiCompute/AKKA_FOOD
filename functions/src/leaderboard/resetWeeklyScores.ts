import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import { PubSub } from "@google-cloud/pubsub";
import { getIsoWeekNumber } from "./rebuildLeaderboard";

/**
 * resetWeeklyScores — Scheduled Cloud Function
 *
 * Runs every Monday at 00:00 UTC (cron: `0 0 * * 1`).
 * Resets all users' weekly scores to zero and cleans up the previous week's
 * leaderboard document.
 *
 * Steps:
 * 1. Query ALL documents in `/userScores` collection
 * 2. Batch-update `weeklyScore = 0` for all documents (max 500 per batch)
 * 3. Delete the previous week's leaderboard document: `/leaderboard/weekly_{prev_week}`
 * 4. Trigger a leaderboard rebuild via Pub/Sub to update the new week's leaderboard
 *
 * Validates:
 * - Req 3 AC5: Weekly period counts only orders completed within the current
 *   calendar week (Monday to Sunday)
 */
export const resetWeeklyScores = onSchedule("0 0 * * 1", async () => {
  const db = admin.firestore();
  const now = new Date();

  functions.logger.info("Starting weekly score reset", {
    timestamp: now.toISOString(),
  });

  // ── 1. Batch-reset weeklyScore = 0 for all userScores documents ─────────
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
      batch.update(doc.ref, { weeklyScore: 0 });
    }
    await batch.commit();

    totalReset += snapshot.docs.length;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    functions.logger.info("Weekly score reset batch committed", {
      batchSize: snapshot.docs.length,
      totalReset,
      timestamp: new Date().toISOString(),
    });

    // If we got fewer than 500 docs, we've reached the end
    if (snapshot.docs.length < 500) {
      break;
    }
  }

  functions.logger.info("All weekly scores reset to zero", {
    totalReset,
    timestamp: new Date().toISOString(),
  });

  // ── 2. Delete previous week's leaderboard document ──────────────────────
  try {
    const prevWeekDocId = getPreviousWeekDocId(now);
    await db.doc(`leaderboard/${prevWeekDocId}`).delete();

    functions.logger.info("Deleted previous week leaderboard document", {
      docId: prevWeekDocId,
      timestamp: new Date().toISOString(),
    });
  } catch (error: unknown) {
    // Non-critical: log but don't fail the function
    functions.logger.warn("Failed to delete previous week leaderboard document", {
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
        reason: "weekly_reset",
        timestamp: now.toISOString(),
      },
    });

    functions.logger.info("Published rebuild-leaderboard message after weekly reset", {
      timestamp: new Date().toISOString(),
    });
  } catch (error: unknown) {
    functions.logger.warn("Failed to publish rebuild-leaderboard message", {
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString(),
    });
  }

  functions.logger.info("Weekly score reset complete", {
    totalReset,
    timestamp: new Date().toISOString(),
  });
});

/**
 * Computes the previous week's leaderboard document ID.
 *
 * Subtracts 7 days from the given date to get a date in the previous week,
 * then uses the shared `getWeeklyDocId` helper to format it.
 */
export function getPreviousWeekDocId(date: Date): string {
  const prevWeek = new Date(date.getTime());
  prevWeek.setDate(prevWeek.getDate() - 7);

  // Use the year from the ISO week calculation for correctness at year boundaries
  const weekNumber = getIsoWeekNumber(prevWeek);
  const year = getIsoWeekYear(prevWeek);
  return `weekly_${year}_${weekNumber.toString().padStart(2, "0")}`;
}

/**
 * Returns the ISO week-numbering year for the given date.
 *
 * The ISO week-numbering year may differ from the calendar year at the
 * boundaries (e.g., Dec 31 might be in week 1 of the next year).
 */
export function getIsoWeekYear(date: Date): number {
  const d = new Date(date.getTime());
  const dayOfWeek = d.getDay() || 7;
  d.setDate(d.getDate() + 4 - dayOfWeek); // Set to Thursday of current week
  return d.getFullYear();
}
