import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { verifyAdmin } from "../helpers/verifyAdmin";
import { sendOrderStatusNotification } from "../helpers/sendOrderStatusNotification";

/**
 * Valid delivery status values.
 */
const VALID_STATUSES = new Set([
  "pending",
  "confirmed",
  "preparing",
  "ready_for_pickup",
  "out_for_delivery",
  "delivered",
  "cancelled",
]);

/**
 * Allowed status transitions.
 * Terminal states (delivered, cancelled) map to an empty set — no transitions allowed.
 */
const ALLOWED_TRANSITIONS: Record<string, Set<string>> = {
  pending: new Set(["confirmed", "cancelled"]),
  confirmed: new Set(["preparing", "cancelled"]),
  preparing: new Set(["ready_for_pickup", "cancelled"]),
  ready_for_pickup: new Set(["out_for_delivery", "delivered", "cancelled"]),
  out_for_delivery: new Set(["delivered", "cancelled"]),
  delivered: new Set(),
  cancelled: new Set(),
};

/**
 * adminUpdateOrderStatus
 *
 * Updates the delivery status of an order.
 * Requires the caller to have the 'admin' role.
 *
 * Request data:
 *   - orderId: string
 *   - status: string  (new delivery status)
 *   - etaMinutes?: number  (required when status == 'out_for_delivery')
 */
export const adminUpdateOrderStatus = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const { orderId, status, etaMinutes } = request.data as {
    orderId: string;
    status: string;
    etaMinutes?: number;
  };

  // ── Field validation ──────────────────────────────────────────────────────
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

  // ── Order existence check ─────────────────────────────────────────────────
  const db = admin.firestore();
  const orderRef = db.doc(`orders/${orderId}`);
  const orderSnap = await orderRef.get();

  if (!orderSnap.exists) {
    throw new HttpsError("not-found", `Order ${orderId} not found.`);
  }

  const orderData = orderSnap.data() as Record<string, unknown>;
  const currentStatus = orderData["status"] as string | undefined;

  // ── Status transition validation ──────────────────────────────────────────
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

  // ── Persist the update ────────────────────────────────────────────────────
  const updateData: Record<string, unknown> = {
    status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (status === "out_for_delivery" && etaMinutes !== undefined) {
    updateData["etaMinutes"] = etaMinutes;
  }

  await orderRef.update(updateData);

  // ── Push notification to customer (Requirement 4.3) ───────────────────────
  const uid = orderData["uid"] as string | undefined;
  if (uid) {
    await sendOrderStatusNotification(orderId, uid, status, etaMinutes);
  }

  return { success: true };
});
