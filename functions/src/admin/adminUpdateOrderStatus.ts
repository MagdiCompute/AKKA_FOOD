import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { verifyAdmin } from "../helpers/verifyAdmin";

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

  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError("invalid-argument", "orderId is required.");
  }
  if (!status || typeof status !== "string") {
    throw new HttpsError("invalid-argument", "status is required.");
  }
  if (status === "out_for_delivery" && typeof etaMinutes !== "number") {
    throw new HttpsError(
      "invalid-argument",
      "etaMinutes is required when status is out_for_delivery."
    );
  }

  const db = admin.firestore();
  const orderRef = db.doc(`orders/${orderId}`);
  const orderSnap = await orderRef.get();

  if (!orderSnap.exists) {
    throw new HttpsError("not-found", `Order ${orderId} not found.`);
  }

  const updateData: Record<string, unknown> = { status };
  if (status === "out_for_delivery" && etaMinutes !== undefined) {
    updateData["etaMinutes"] = etaMinutes;
  }

  await orderRef.update(updateData);

  return { success: true };
});
