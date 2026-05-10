import * as admin from "firebase-admin";

/**
 * Human-readable labels for each delivery status, used in push notification bodies.
 */
const STATUS_LABELS: Record<string, string> = {
  confirmed: "Your order has been confirmed!",
  preparing: "Your order is being prepared.",
  ready_for_pickup: "Your order is ready for pickup.",
  out_for_delivery: "Your order is on its way!",
  delivered: "Your order has been delivered. Enjoy!",
  cancelled: "Your order has been cancelled.",
};

/**
 * Sends a push notification to the customer when their order status changes.
 *
 * Looks up the customer's FCM token from `/users/{uid}.fcmToken`.
 * Silently skips if the user has no FCM token (e.g. they haven't granted
 * notification permission or the token hasn't been stored yet).
 *
 * @param orderId  - The Firestore order document ID.
 * @param uid      - The customer's Firebase Auth UID.
 * @param newStatus - The new delivery status string.
 * @param etaMinutes - Optional ETA in minutes (only relevant for out_for_delivery).
 */
export async function sendOrderStatusNotification(
  orderId: string,
  uid: string,
  newStatus: string,
  etaMinutes?: number
): Promise<void> {
  const db = admin.firestore();
  const userSnap = await db.doc(`users/${uid}`).get();

  if (!userSnap.exists) return;

  const fcmToken = userSnap.data()?.["fcmToken"] as string | undefined;
  if (!fcmToken) return;

  const body = buildNotificationBody(newStatus, etaMinutes);

  const message: admin.messaging.Message = {
    token: fcmToken,
    notification: {
      title: "Order Update",
      body,
    },
    data: {
      orderId,
      status: newStatus,
    },
    android: {
      notification: {
        channelId: "order_updates",
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
  } catch (err) {
    // Log but don't fail the status update if notification delivery fails.
    console.error(
      `[sendOrderStatusNotification] Failed to send FCM message for order ${orderId}:`,
      err
    );
  }
}

function buildNotificationBody(status: string, etaMinutes?: number): string {
  if (status === "out_for_delivery" && typeof etaMinutes === "number") {
    return `Your order is on its way! Estimated arrival: ${etaMinutes} minute${etaMinutes === 1 ? "" : "s"}.`;
  }
  return STATUS_LABELS[status] ?? `Your order status has been updated to: ${status}.`;
}
