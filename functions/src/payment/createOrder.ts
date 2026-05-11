import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as functions from "firebase-functions";

/**
 * createOrder — HTTPS Callable Cloud Function
 *
 * Standalone callable for creating an order from a successful transaction's
 * cart snapshot. Useful for admin retry scenarios or independent invocation
 * when the automatic post-payment flow needs to be re-triggered.
 *
 * Steps:
 * 1. Validate caller's auth token
 * 2. Validate the transaction exists and has status `success`
 * 3. Check idempotency: if an order already exists for this transaction, return it
 * 4. Read cart snapshot from `/transactions/{transactionId}/cartSnapshot/items`
 * 5. Create `/orders/{orderId}` with order data
 * 6. Link orderId back to the transaction document
 * 7. Return { orderId }
 *
 * Validates:
 * - Req 2 AC2: Order_Service SHALL create a new Order from Cart summary with unique Order ID
 * - Req 6 AC4: Idempotency — processing same request twice SHALL NOT create duplicate Orders
 */
export const createOrder = onCall(async (request) => {
  // ── Step 1: Validate caller's auth token ──────────────────────────────
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to create an order."
    );
  }

  const uid = request.auth.uid;

  // ── Validate request data ─────────────────────────────────────────────
  const { transactionId } = request.data as { transactionId: string };

  if (!transactionId || typeof transactionId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "transactionId is required and must be a string."
    );
  }

  const db = admin.firestore();

  // ── Step 2: Validate the transaction exists and has status `success` ───
  const transactionRef = db.collection("transactions").doc(transactionId);
  const transactionDoc = await transactionRef.get();

  if (!transactionDoc.exists) {
    throw new HttpsError(
      "not-found",
      "Transaction not found."
    );
  }

  const transactionData = transactionDoc.data()!;

  // Verify the caller owns this transaction (unless admin)
  if (transactionData.uid !== uid) {
    // Check if caller is admin
    const userDoc = await db.collection("users").doc(uid).get();
    const isAdmin = userDoc.exists && userDoc.data()?.role === "admin";

    if (!isAdmin) {
      throw new HttpsError(
        "permission-denied",
        "You do not have permission to create an order for this transaction."
      );
    }
  }

  if (transactionData.status !== "success") {
    throw new HttpsError(
      "failed-precondition",
      `Transaction status is '${transactionData.status}'. Only successful transactions can generate orders.`
    );
  }

  // ── Step 3: Idempotency check — return existing order if already created ─
  if (transactionData.orderId) {
    functions.logger.info("Order already exists for transaction (idempotent return)", {
      transactionId,
      orderId: transactionData.orderId,
      uid,
      timestamp: new Date().toISOString(),
    });

    return { orderId: transactionData.orderId };
  }

  // ── Step 4: Read cart snapshot ────────────────────────────────────────
  const snapshotDoc = await transactionRef
    .collection("cartSnapshot")
    .doc("items")
    .get();

  let items: unknown[] = [];

  if (snapshotDoc.exists) {
    const snapshotData = snapshotDoc.data();
    items = snapshotData?.items || [];
  } else {
    // Fallback: read current cart
    const cartDoc = await db.collection("carts").doc(transactionData.uid).get();
    if (cartDoc.exists) {
      const cartData = cartDoc.data();
      items = cartData?.items || [];
    }
    functions.logger.warn("Cart snapshot not found, using current cart", {
      transactionId,
      uid: transactionData.uid,
      timestamp: new Date().toISOString(),
    });
  }

  // ── Step 5: Create order document ─────────────────────────────────────
  const orderData = {
    uid: transactionData.uid,
    items,
    totalAmount: transactionData.amount,
    status: "confirmed",
    transactionId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const orderRef = await db.collection("orders").add(orderData);
  const orderId = orderRef.id;

  // ── Step 6: Link orderId back to the transaction ──────────────────────
  await transactionRef.update({
    orderId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  functions.logger.info("Order created via createOrder callable", {
    orderId,
    transactionId,
    uid: transactionData.uid,
    totalAmount: transactionData.amount,
    itemCount: Array.isArray(items) ? items.length : 0,
    timestamp: new Date().toISOString(),
  });

  return { orderId };
});
