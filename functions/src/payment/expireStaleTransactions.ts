import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";

/**
 * expireStaleTransactions — Scheduled Cloud Function
 *
 * Runs every 1 minute to find and expire stale pending transactions.
 * A transaction is considered stale if it has been in `pending` status
 * for more than 5 minutes.
 *
 * Validates:
 * - Req 3 AC1: When the payment times out after 5 minutes, update Transaction status to `failed`
 * - Req 6 AC3: Log all Transaction state changes with timestamps for audit purposes
 */
export const expireStaleTransactions = onSchedule("every 1 minutes", async () => {
  const db = admin.firestore();
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

  // Query all pending transactions older than 5 minutes
  const staleTransactions = await db
    .collection("transactions")
    .where("status", "==", "pending")
    .where("createdAt", "<", fiveMinutesAgo)
    .get();

  if (staleTransactions.empty) {
    functions.logger.info("No stale transactions found", {
      timestamp: new Date().toISOString(),
    });
    return;
  }

  // Use batch writes for efficiency
  const batchSize = 500; // Firestore batch limit
  const docs = staleTransactions.docs;

  for (let i = 0; i < docs.length; i += batchSize) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + batchSize);

    for (const doc of chunk) {
      batch.update(doc.ref, {
        status: "failed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Audit log: Transaction state change (Req 6 AC3)
      functions.logger.info("Transaction expired", {
        transactionId: doc.id,
        reference: doc.data().reference,
        uid: doc.data().uid,
        oldStatus: "pending",
        newStatus: "failed",
        reason: "Payment timeout — pending for more than 5 minutes",
        timestamp: new Date().toISOString(),
      });
    }

    await batch.commit();
  }

  functions.logger.info("Stale transactions expired", {
    count: docs.length,
    timestamp: new Date().toISOString(),
  });
});
