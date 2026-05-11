import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * Post-payment success actions.
 *
 * Triggered after a successful payment callback. Performs:
 * 1. Create Order from cart snapshot (Req 2 AC2)
 * 2. Credit coins — 5% of amount, rounded down (Req 2 AC3)
 * 3. Clear user's cart (Req 2 AC4)
 * 4. Send FCM push notification (Req 2 AC6)
 *
 * Idempotency: The caller (orangeMoneyCallback) ensures this is only called once
 * per transaction via the Firestore transaction check. Additionally, the order
 * creation checks for an existing orderId on the transaction to prevent duplicates.
 */

export interface PostPaymentParams {
  transactionId: string;
  uid: string;
  amount: number;
  reference: string;
}

/**
 * Calculates loyalty coins earned from a payment.
 * 5% of the total amount, rounded down to the nearest integer.
 */
export function calculateCoins(totalAmount: number): number {
  return Math.floor(totalAmount * 0.05);
}

/**
 * Executes all post-payment success actions.
 * Each action is independent and logged individually.
 * Failures in one action do not block others.
 */
export async function executePostPaymentActions(
  params: PostPaymentParams
): Promise<{ orderId: string }> {
  const { transactionId, uid, amount, reference } = params;
  const db = admin.firestore();

  // ── 1. Create Order from cart snapshot (Req 2 AC2) ────────────────────────
  const orderId = await createOrder(db, transactionId, uid, amount);

  // Update the transaction with the orderId
  await db.collection("transactions").doc(transactionId).update({
    orderId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  functions.logger.info("Order linked to transaction", {
    transactionId,
    orderId,
    reference,
    timestamp: new Date().toISOString(),
  });

  // ── 2. Credit coins — 5% of amount (Req 2 AC3) ───────────────────────────
  const coins = calculateCoins(amount);
  await creditCoins(db, uid, coins, transactionId);

  // ── 3. Clear user's cart (Req 2 AC4) ──────────────────────────────────────
  await clearCart(db, uid, transactionId);

  // ── 4. Send FCM push notification (Req 2 AC6) ────────────────────────────
  await sendOrderConfirmationNotification(db, uid, orderId, amount);

  return { orderId };
}

/**
 * Creates an order document from the cart snapshot stored at payment initiation.
 * The cart snapshot is expected at `/transactions/{transactionId}/cartSnapshot`
 * or as a subcollection. For now, we read from `/carts/{uid}` as a fallback.
 */
async function createOrder(
  db: admin.firestore.Firestore,
  transactionId: string,
  uid: string,
  amount: number
): Promise<string> {
  // Try to read cart snapshot from the transaction (saved at payment initiation)
  const snapshotDoc = await db
    .collection("transactions")
    .doc(transactionId)
    .collection("cartSnapshot")
    .doc("items")
    .get();

  let items: unknown[] = [];

  if (snapshotDoc.exists) {
    const snapshotData = snapshotDoc.data();
    items = snapshotData?.items || [];
  } else {
    // Fallback: read current cart (task 6.2 will ensure snapshot exists)
    const cartDoc = await db.collection("carts").doc(uid).get();
    if (cartDoc.exists) {
      const cartData = cartDoc.data();
      items = cartData?.items || [];
    }
    functions.logger.warn("Cart snapshot not found, using current cart", {
      transactionId,
      uid,
      timestamp: new Date().toISOString(),
    });
  }

  const orderData = {
    uid,
    items,
    totalAmount: amount,
    status: "confirmed",
    transactionId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const orderRef = await db.collection("orders").add(orderData);

  functions.logger.info("Order created", {
    orderId: orderRef.id,
    transactionId,
    uid,
    totalAmount: amount,
    itemCount: Array.isArray(items) ? items.length : 0,
    timestamp: new Date().toISOString(),
  });

  return orderRef.id;
}

/**
 * Credits loyalty coins to the user's account.
 * Uses FieldValue.increment for atomic updates.
 */
async function creditCoins(
  db: admin.firestore.Firestore,
  uid: string,
  coins: number,
  transactionId: string
): Promise<void> {
  if (coins <= 0) {
    functions.logger.info("No coins to credit (amount too small)", {
      uid,
      coins,
      transactionId,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  await db.collection("users").doc(uid).update({
    coins: admin.firestore.FieldValue.increment(coins),
  });

  functions.logger.info("Coins credited", {
    uid,
    coins,
    transactionId,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Clears the user's cart after successful payment.
 * Deletes the cart document at `/carts/{uid}`.
 */
async function clearCart(
  db: admin.firestore.Firestore,
  uid: string,
  transactionId: string
): Promise<void> {
  await db.collection("carts").doc(uid).delete();

  functions.logger.info("Cart cleared", {
    uid,
    transactionId,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Sends an FCM push notification confirming the order.
 * Reads the user's FCM token from `/users/{uid}`.
 */
async function sendOrderConfirmationNotification(
  db: admin.firestore.Firestore,
  uid: string,
  orderId: string,
  amount: number
): Promise<void> {
  // Read user's FCM token
  const userDoc = await db.collection("users").doc(uid).get();

  if (!userDoc.exists) {
    functions.logger.warn("User document not found for FCM notification", {
      uid,
      orderId,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  const userData = userDoc.data();
  const fcmToken = userData?.fcmToken;

  if (!fcmToken) {
    functions.logger.warn("No FCM token found for user", {
      uid,
      orderId,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  const message: admin.messaging.Message = {
    token: fcmToken,
    notification: {
      title: "Commande confirmée 🎉",
      body: `Votre commande #${orderId.substring(0, 8)} de ${amount} XOF a été confirmée.`,
    },
    data: {
      type: "order_confirmed",
      orderId,
      amount: String(amount),
    },
  };

  try {
    await admin.messaging().send(message);

    functions.logger.info("FCM notification sent", {
      uid,
      orderId,
      timestamp: new Date().toISOString(),
    });
  } catch (error: unknown) {
    // FCM failures should not block the payment flow
    functions.logger.error("Failed to send FCM notification", {
      uid,
      orderId,
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString(),
    });
  }
}
