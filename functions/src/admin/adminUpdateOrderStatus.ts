import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { verifyAdmin } from "../helpers/verifyAdmin";
import { sendOrderStatusNotification } from "../helpers/sendOrderStatusNotification";

/**
 * Valid delivery status values per the design doc.
 */
const VALID_STATUSES = new Set([
  "pending",
  "confirmed",
  "preparing",
  "out_for_delivery",
  "delivered",
  "failed",
]);

/**
 * Allowed status transitions per the design doc:
 *   pending → confirmed → preparing → out_for_delivery → delivered
 *                                                       → failed
 *
 * Terminal states (delivered, failed) have no outgoing transitions.
 */
const ALLOWED_TRANSITIONS: Record<string, Set<string>> = {
  pending: new Set(["confirmed"]),
  confirmed: new Set(["preparing"]),
  preparing: new Set(["out_for_delivery"]),
  out_for_delivery: new Set(["delivered", "failed"]),
  delivered: new Set(),
  failed: new Set(),
};

/**
 * adminUpdateOrderStatus
 *
 * HTTPS Callable Cloud Function that updates the delivery status of an order.
 * Requires the caller to have the 'admin' role (checked via users/{uid}.role).
 *
 * Request data:
 *   - orderId: string        — the order document ID
 *   - status: string         — the new delivery status
 *   - etaMinutes?: number    — required when status is 'out_for_delivery'
 *
 * Returns: { success: true } on success.
 *
 * Error codes:
 *   - unauthenticated    — caller is not authenticated
 *   - permission-denied  — caller is not an admin
 *   - invalid-argument   — missing/invalid fields or etaMinutes not provided for out_for_delivery
 *   - not-found          — order does not exist
 *   - failed-precondition — illegal status transition
 */
export const adminUpdateOrderStatus = onCall(async (request) => {
  // 1. Validate admin role
  await verifyAdmin(request.auth);

  const { orderId, status, etaMinutes } = request.data as {
    orderId: string;
    status: string;
    etaMinutes?: number;
  };

  // 2. Field validation
  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "orderId is required.");
  }
  if (!status || typeof status !== "string") {
    throw new HttpsError("invalid-argument", "status is required.");
  }
  if (!VALID_STATUSES.has(status)) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid status value: ${status}.`
    );
  }
  if (status === "out_for_delivery" && typeof etaMinutes !== "number") {
    throw new HttpsError(
      "invalid-argument",
      "etaMinutes is required when status is out_for_delivery."
    );
  }

  // 3. Order existence check
  const db = admin.firestore();
  const orderRef = db.doc(`orders/${orderId}`);
  const orderSnap = await orderRef.get();

  if (!orderSnap.exists) {
    throw new HttpsError("not-found", `Order ${orderId} not found.`);
  }

  const orderData = orderSnap.data() as Record<string, unknown>;
  const currentStatus = orderData["status"] as string | undefined;

  // 4. Status transition validation
  if (!currentStatus || !ALLOWED_TRANSITIONS[currentStatus]) {
    throw new HttpsError(
      "failed-precondition",
      `Order ${orderId} has an unrecognised current status: ${currentStatus}.`
    );
  }

  if (!ALLOWED_TRANSITIONS[currentStatus].has(status)) {
    throw new HttpsError(
      "failed-precondition",
      `Invalid status transition from ${currentStatus} to ${status}.`
    );
  }

  // 5. Persist the update
  const updateData: Record<string, unknown> = {
    status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (status === "out_for_delivery" && etaMinutes !== undefined) {
    updateData["etaMinutes"] = etaMinutes;
  }

  await orderRef.update(updateData);

  // 6. Send push notification to customer
  const uid = orderData["uid"] as string | undefined;
  if (uid) {
    await sendOrderStatusNotification(orderId, uid, status, etaMinutes);
  }

  return { success: true };
});
