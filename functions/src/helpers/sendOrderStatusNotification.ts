import * as admin from "firebase-admin";

/**
 * Builds the push notification payload for a given delivery status.
 * Payloads match the design doc specification exactly.
 *
 * @param status - The new delivery status string.
 * @param orderId - The Firestore order document ID.
 * @param etaMinutes - Optional ETA in minutes (used for out_for_delivery).
 * @returns Notification payload with title, body, and data, or null for unknown statuses.
 */
export function buildNotificationPayload(
  status: string,
  orderId: string,
  etaMinutes?: number
): { title: string; body: string; data: Record<string, string> } | null {
  switch (status) {
    case "confirmed":
      return {
        title: "Order confirmed",
        body: "Your order has been confirmed!",
        data: { orderId },
      };
    case "preparing":
      return {
        title: "Order update",
        body: "Your order is being prepared.",
        data: { orderId },
      };
    case "out_for_delivery":
      return {
        title: "Your order is on the way!",
        body: `ETA: ${etaMinutes ?? "?"} minutes`,
        data: { orderId },
      };
    case "delivered":
      return {
        title: "Order delivered!",
        body: "Tap to rate your experience",
        data: { orderId },
      };
    case "failed":
      return {
        title: "Delivery issue",
        body: "We couldn't deliver your order. We'll contact you shortly.",
        data: { orderId },
      };
    default:
      return null;
  }
}

/**
 * Sends a push notification to the customer when their order status changes.
 *
 * Looks up the customer's FCM token from `/users/{uid}.fcmToken`.
 * Silently skips if the user has no FCM token (e.g. they haven't granted
 * notification permission or the token hasn't been stored yet).
 *
 * The notification includes:
 * - Per-status title and body matching the design doc
 * - Data payload with orderId, status, and type for deep linking
 * - Android notification channel ("order_updates") with high priority
 * - iOS default sound
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

  const userData = userSnap.data();
  const fcmToken = userData?.["fcmToken"] as string | undefined;
  if (!fcmToken) return;

  // Check user notification preferences — default to enabled if not explicitly set
  const preferences = userData?.["preferences"] as Record<string, unknown> | undefined;
  const notificationsEnabled = preferences?.notificationsEnabled !== false;
  if (!notificationsEnabled) return;

  const payload = buildNotificationPayload(newStatus, orderId, etaMinutes);
  if (!payload) return;

  const message: admin.messaging.Message = {
    token: fcmToken,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      ...payload.data,
      status: newStatus,
      type: "order_status_update",
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
