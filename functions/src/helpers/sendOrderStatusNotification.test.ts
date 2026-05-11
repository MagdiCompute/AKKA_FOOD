/**
 * Unit tests for sendOrderStatusNotification helper.
 *
 * Validates: Requirements 3.1, 3.2, 3.3, 3.4
 *
 * Tests that push notification payloads match the design doc for each status,
 * include proper data fields for deep linking, and respect user preferences.
 */

// ---- Mock firebase-admin ----
const mockGet = jest.fn();
const mockDoc = jest.fn(() => ({ get: mockGet }));
const mockFirestore = jest.fn(() => ({ doc: mockDoc }));
const mockSend = jest.fn();
const mockMessaging = jest.fn(() => ({ send: mockSend }));

jest.mock("firebase-admin", () => ({
  firestore: Object.assign(mockFirestore, {
    FieldValue: { serverTimestamp: jest.fn() },
  }),
  messaging: mockMessaging,
  apps: [true],
  initializeApp: jest.fn(),
}));

// Import AFTER mocks are set up
import {
  buildNotificationPayload,
  sendOrderStatusNotification,
} from "./sendOrderStatusNotification";

// Helper to make mockGet resolve with a Firestore-like snapshot
function makeUserSnapshot(
  exists: boolean,
  data?: Record<string, unknown>
) {
  return {
    exists,
    data: () => data,
  };
}

describe("buildNotificationPayload", () => {
  it("returns correct payload for 'confirmed' status", () => {
    const payload = buildNotificationPayload("confirmed", "order-123");
    expect(payload).toEqual({
      title: "Order confirmed",
      body: "Your order has been confirmed!",
      data: { orderId: "order-123" },
    });
  });

  it("returns correct payload for 'preparing' status", () => {
    const payload = buildNotificationPayload("preparing", "order-456");
    expect(payload).toEqual({
      title: "Order update",
      body: "Your order is being prepared.",
      data: { orderId: "order-456" },
    });
  });

  it("returns correct payload for 'out_for_delivery' with etaMinutes", () => {
    const payload = buildNotificationPayload("out_for_delivery", "order-789", 15);
    expect(payload).toEqual({
      title: "Your order is on the way!",
      body: "ETA: 15 minutes",
      data: { orderId: "order-789" },
    });
  });

  it("returns correct payload for 'out_for_delivery' without etaMinutes", () => {
    const payload = buildNotificationPayload("out_for_delivery", "order-789");
    expect(payload).toEqual({
      title: "Your order is on the way!",
      body: "ETA: ? minutes",
      data: { orderId: "order-789" },
    });
  });

  it("returns correct payload for 'delivered' status", () => {
    const payload = buildNotificationPayload("delivered", "order-abc");
    expect(payload).toEqual({
      title: "Order delivered!",
      body: "Tap to rate your experience",
      data: { orderId: "order-abc" },
    });
  });

  it("returns correct payload for 'failed' status", () => {
    const payload = buildNotificationPayload("failed", "order-def");
    expect(payload).toEqual({
      title: "Delivery issue",
      body: "We couldn't deliver your order. We'll contact you shortly.",
      data: { orderId: "order-def" },
    });
  });

  it("returns null for unknown status", () => {
    const payload = buildNotificationPayload("unknown_status", "order-xyz");
    expect(payload).toBeNull();
  });

  it("returns null for 'pending' status (no notification for pending)", () => {
    const payload = buildNotificationPayload("pending", "order-xyz");
    expect(payload).toBeNull();
  });
});

describe("sendOrderStatusNotification", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("skips notification when user document does not exist", async () => {
    mockGet.mockResolvedValueOnce(makeUserSnapshot(false));

    await sendOrderStatusNotification("order-1", "uid-1", "confirmed");

    expect(mockSend).not.toHaveBeenCalled();
  });

  it("skips notification when user has no FCM token", async () => {
    mockGet.mockResolvedValueOnce(
      makeUserSnapshot(true, { preferences: { notificationsEnabled: true } })
    );

    await sendOrderStatusNotification("order-1", "uid-1", "confirmed");

    expect(mockSend).not.toHaveBeenCalled();
  });

  it("skips notification when user has notifications disabled", async () => {
    mockGet.mockResolvedValueOnce(
      makeUserSnapshot(true, {
        fcmToken: "token-abc",
        preferences: { notificationsEnabled: false },
      })
    );

    await sendOrderStatusNotification("order-1", "uid-1", "confirmed");

    expect(mockSend).not.toHaveBeenCalled();
  });

  it("skips notification for unknown status (no payload)", async () => {
    mockGet.mockResolvedValueOnce(
      makeUserSnapshot(true, {
        fcmToken: "token-abc",
        preferences: { notificationsEnabled: true },
      })
    );

    await sendOrderStatusNotification("order-1", "uid-1", "pending");

    expect(mockSend).not.toHaveBeenCalled();
  });

  it("sends notification with correct payload for 'confirmed'", async () => {
    mockGet.mockResolvedValueOnce(
      makeUserSnapshot(true, {
        fcmToken: "token-abc",
        preferences: { notificationsEnabled: true },
      })
    );
    mockSend.mockResolvedValueOnce("message-id");

    await sendOrderStatusNotification("order-1", "uid-1", "confirmed");

    expect(mockSend).toHaveBeenCalledTimes(1);
    const message = mockSend.mock.calls[0][0];
    expect(message.token).toBe("token-abc");
    expect(message.notification).toEqual({
      title: "Order confirmed",
      body: "Your order has been confirmed!",
    });
    expect(message.data).toEqual({
      orderId: "order-1",
      status: "confirmed",
      type: "order_status_update",
    });
  });

  it("sends notification with correct payload for 'out_for_delivery' with ETA", async () => {
    mockGet.mockResolvedValueOnce(
      makeUserSnapshot(true, {
        fcmToken: "token-xyz",
        preferences: { notificationsEnabled: true },
      })
    );
    mockSend.mockResolvedValueOnce("message-id");

    await sendOrderStatusNotification("order-2", "uid-2", "out_for_delivery", 20);

    expect(mockSend).toHaveBeenCalledTimes(1);
    const message = mockSend.mock.calls[0][0];
    expect(message.notification).toEqual({
      title: "Your order is on the way!",
      body: "ETA: 20 minutes",
    });
    expect(message.data).toEqual({
      orderId: "order-2",
      status: "out_for_delivery",
      type: "order_status_update",
    });
  });

  it("includes Android channel and iOS sound in the message", async () => {
    mockGet.mockResolvedValueOnce(
      makeUserSnapshot(true, {
        fcmToken: "token-platform",
        preferences: { notificationsEnabled: true },
      })
    );
    mockSend.mockResolvedValueOnce("message-id");

    await sendOrderStatusNotification("order-3", "uid-3", "delivered");

    const message = mockSend.mock.calls[0][0];
    expect(message.android).toEqual({
      notification: {
        channelId: "order_updates",
        priority: "high",
      },
    });
    expect(message.apns).toEqual({
      payload: {
        aps: {
          sound: "default",
        },
      },
    });
  });

  it("defaults notificationsEnabled to true when preferences are not set", async () => {
    mockGet.mockResolvedValueOnce(
      makeUserSnapshot(true, {
        fcmToken: "token-no-prefs",
      })
    );
    mockSend.mockResolvedValueOnce("message-id");

    await sendOrderStatusNotification("order-4", "uid-4", "preparing");

    expect(mockSend).toHaveBeenCalledTimes(1);
    const message = mockSend.mock.calls[0][0];
    expect(message.notification).toEqual({
      title: "Order update",
      body: "Your order is being prepared.",
    });
  });

  it("does not throw when FCM send fails", async () => {
    mockGet.mockResolvedValueOnce(
      makeUserSnapshot(true, {
        fcmToken: "token-fail",
        preferences: { notificationsEnabled: true },
      })
    );
    mockSend.mockRejectedValueOnce(new Error("FCM unavailable"));

    // Should not throw
    await expect(
      sendOrderStatusNotification("order-5", "uid-5", "failed")
    ).resolves.toBeUndefined();
  });
});
