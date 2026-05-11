import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

/**
 * Calculates loyalty coins earned from a payment amount.
 * 5% of the total amount, rounded down to the nearest integer.
 *
 * Validates: Req 1 AC1 — Credit coins equal to floor(totalAmount * 0.05)
 */
export function calculateCoins(amount: number): number {
  return Math.floor(amount * 0.05);
}

/**
 * onPaymentSuccess — Firestore trigger on `/transactions/{id}`
 *
 * Fires when a transaction document is updated. Checks if the status
 * changed to 'success' and credits loyalty coins to the user.
 *
 * Steps:
 * 1. Detect status change to 'success'
 * 2. Compute coins: floor(amount * 0.05)
 * 3. If coins === 0, return (no coins for zero-cash orders) — Req 1 AC5
 * 4. Idempotency pre-check: query for existing CoinTransaction with same orderId — Req 1 AC3
 * 5. Atomic Firestore transaction with deterministic doc ID (`reward_{orderId}`) — Req 5 AC2
 *    - Inside the transaction, re-check the deterministic doc to prevent race conditions
 *    - Uses `t.get()` on the deterministic doc ref for transactional consistency
 *
 * Validates:
 * - Req 1 AC1: Credit coins equal to floor(totalAmount * 0.05)
 * - Req 1 AC2: Create CoinTransaction record with amount, reason, orderId, timestamp
 * - Req 1 AC3: Credit coins only once per payment (idempotency)
 * - Req 1 AC5: No coins for zero-cash orders
 * - Req 5 AC2: Use Firestore transactions for atomic updates
 */
export const onPaymentSuccess = onDocumentUpdated(
  "transactions/{transactionId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      functions.logger.warn("onPaymentSuccess: Missing before/after data");
      return;
    }

    const previousStatus = beforeData.status as string | undefined;
    const newStatus = afterData.status as string | undefined;

    // Only proceed if status changed to 'success'
    if (newStatus !== "success" || previousStatus === "success") {
      return;
    }

    const transactionId = event.params.transactionId;
    const uid = afterData.uid as string | undefined;
    const amount = afterData.amount as number | undefined;
    const orderId = (afterData.orderId as string | undefined) || transactionId;

    if (!uid) {
      functions.logger.error("onPaymentSuccess: Missing uid on transaction", {
        transactionId,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    if (amount === undefined || amount === null) {
      functions.logger.error("onPaymentSuccess: Missing amount on transaction", {
        transactionId,
        uid,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    // ── Step 2: Compute coins ─────────────────────────────────────────────────
    const coins = calculateCoins(amount);

    // ── Step 3: No coins for zero-cash orders (Req 1 AC5) ─────────────────────
    if (coins === 0) {
      functions.logger.info("No coins to credit (zero-cash order or amount too small)", {
        transactionId,
        uid,
        amount,
        coins,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    const db = admin.firestore();

    // ── Step 4: Idempotency check by orderId (Req 1 AC3) ──────────────────────
    // Pre-check: fast-path to avoid unnecessary transaction overhead
    const existingTxQuery = await db
      .collection("users")
      .doc(uid)
      .collection("coinTransactions")
      .where("orderId", "==", orderId)
      .limit(1)
      .get();

    if (!existingTxQuery.empty) {
      functions.logger.info("Coin transaction already exists for this order (idempotency)", {
        transactionId,
        uid,
        orderId,
        timestamp: new Date().toISOString(),
      });
      return;
    }

    // ── Step 5: Atomic Firestore transaction with idempotency guard (Req 5 AC2) ──
    // Use a deterministic document ID derived from orderId to guarantee at-most-once
    // semantics even under concurrent execution. The `create()` call will fail if
    // the document already exists, preventing double-crediting.
    const coinTxRef = db
      .collection("users")
      .doc(uid)
      .collection("coinTransactions")
      .doc(`reward_${orderId}`);

    try {
      await db.runTransaction(async (t) => {
        // Read the deterministic coin transaction doc inside the transaction
        const existingCoinTx = await t.get(coinTxRef);

        if (existingCoinTx.exists) {
          // Another concurrent execution already credited coins for this order
          functions.logger.info("Coin transaction already exists inside transaction (race condition prevented)", {
            transactionId,
            uid,
            orderId,
            timestamp: new Date().toISOString(),
          });
          return;
        }

        const userRef = db.doc(`users/${uid}`);
        const userSnap = await t.get(userRef);

        const currentBalance = (userSnap.data()?.coinBalance as number) || 0;

        // Create CoinTransaction record with deterministic ID (Req 1 AC2)
        t.set(coinTxRef, {
          amount: coins,
          reason: "Purchase reward",
          orderId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update user's coinBalance atomically
        t.update(userRef, {
          coinBalance: currentBalance + coins,
        });
      });

      functions.logger.info("Coins credited successfully", {
        transactionId,
        uid,
        orderId,
        coins,
        timestamp: new Date().toISOString(),
      });
    } catch (error: unknown) {
      functions.logger.error("Failed to credit coins", {
        transactionId,
        uid,
        orderId,
        coins,
        error: error instanceof Error ? error.message : String(error),
        timestamp: new Date().toISOString(),
      });
      throw error; // Re-throw to trigger Cloud Functions retry
    }
  }
);
