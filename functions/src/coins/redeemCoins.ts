import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

/**
 * Validates that the redeemed coins amount is a positive multiple of 1000.
 *
 * Validates: Req 2 AC2 — Only allow redemption in multiples of 1000
 */
export function validateRedemptionAmount(redeemedCoins: number): boolean {
  return (
    typeof redeemedCoins === "number" &&
    Number.isInteger(redeemedCoins) &&
    redeemedCoins > 0 &&
    redeemedCoins % 1000 === 0
  );
}

/**
 * redeemCoins — HTTPS Callable Cloud Function
 *
 * Called from the Cart checkout flow to redeem loyalty coins for a discount.
 *
 * Steps:
 * 1. Validate caller is authenticated
 * 2. Validate redeemedCoins is a positive multiple of 1000
 * 3. Atomic Firestore transaction:
 *    a. Read current coinBalance from /users/{uid}
 *    b. Verify balance >= redeemedCoins (Req 2 AC1, Req 2 AC5)
 *    c. Create CoinTransaction doc with amount (-redeemedCoins), reason "Redemption", orderId, timestamp
 *    d. Update coinBalance (balance - redeemedCoins)
 * 4. Return success
 *
 * Validates:
 * - Req 2 AC1: Verify balance >= 1000 before allowing redemption
 * - Req 2 AC2: Only allow redemption in multiples of 1000
 * - Req 2 AC3: Debit redeemed amount and create CoinTransaction with reason "Redemption"
 * - Req 2 AC5: Ensure balance never goes below 0
 * - Req 5 AC2: Use Firestore transactions for atomic updates
 */
export const redeemCoins = onCall(async (request) => {
  // ── Step 1: Validate authentication ───────────────────────────────────────
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to redeem coins.");
  }

  const uid = request.auth.uid;
  const { redeemedCoins, orderId } = request.data as {
    redeemedCoins: unknown;
    orderId: unknown;
  };

  // ── Step 2: Validate redeemedCoins is a multiple of 1000 (Req 2 AC2) ─────
  if (!validateRedemptionAmount(redeemedCoins as number)) {
    throw new HttpsError(
      "invalid-argument",
      "Redeemed coins must be a positive integer and a multiple of 1000."
    );
  }

  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "A valid orderId is required.");
  }

  const amount = redeemedCoins as number;
  const db = admin.firestore();

  // ── Step 3: Atomic Firestore transaction (Req 5 AC2) ──────────────────────
  try {
    await db.runTransaction(async (t) => {
      const userRef = db.doc(`users/${uid}`);
      const userSnap = await t.get(userRef);

      const balance = (userSnap.data()?.coinBalance as number) || 0;

      // Verify balance >= redeemedCoins (Req 2 AC1, Req 2 AC5)
      if (balance < amount) {
        throw new HttpsError(
          "failed-precondition",
          "Insufficient coins. Current balance is less than the requested redemption amount."
        );
      }

      // Create CoinTransaction record (Req 2 AC3)
      const coinTxRef = db
        .collection("users")
        .doc(uid)
        .collection("coinTransactions")
        .doc();

      t.set(coinTxRef, {
        amount: -amount,
        reason: "Redemption",
        orderId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user's coinBalance atomically
      t.update(userRef, {
        coinBalance: balance - amount,
      });
    });

    return { success: true };
  } catch (error: unknown) {
    // Re-throw HttpsError instances directly so the client gets the proper code
    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      "An unexpected error occurred while redeeming coins."
    );
  }
});
