"use strict";
/**
 * Unit tests for onOrderStatusChanged Firestore trigger.
 *
 * Tests cover:
 * - TrackingUpdate record creation on status change
 * - FCM push notification sent when user preferences allow
 * - FCM push notification skipped when user preferences disable notifications
 * - Leaderboard update and coin credit on 'delivered' status
 * - Admin follow-up flag on 'failed' status
 * - No action when status hasn't changed
 */
Object.defineProperty(exports, "__esModule", { value: true });
// ── Mock firebase-admin ─────────────────────────────────────────────────────
const mockAdd = jest.fn().mockResolvedValue({ id: "tracking-update-id" });
const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockSet = jest.fn().mockResolvedValue(undefined);
const mockGet = jest.fn();
const mockCollection = jest.fn();
const mockDoc = jest.fn();
const mockFirestore = {
    collection: mockCollection,
    doc: mockDoc,
};
mockCollection.mockImplementation((path) => {
    if (path.includes("trackingUpdates")) {
        return { add: mockAdd };
    }
    if (path.includes("coinHistory")) {
        return { add: mockAdd };
    }
    if (path === "adminFollowUps") {
        return { add: mockAdd };
    }
    return {
        doc: mockDoc,
        add: mockAdd,
    };
});
mockDoc.mockImplementation(() => ({
    get: mockGet,
    update: mockUpdate,
    set: mockSet,
    collection: mockCollection,
}));
const mockSend = jest.fn().mockResolvedValue("message-id");
jest.mock("firebase-admin", () => ({
    firestore: Object.assign(() => mockFirestore, {
        FieldValue: {
            serverTimestamp: () => "SERVER_TIMESTAMP",
            increment: (n) => ({ _increment: n }),
        },
    }),
    messaging: () => ({
        send: mockSend,
    }),
    apps: [{}],
}));
jest.mock("firebase-functions", () => ({
    logger: {
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    },
}));
jest.mock("firebase-functions/v2/firestore", () => ({
    onDocumentUpdated: (_path, handler) => handler,
}));
// ── Import the handler (after mocks) ────────────────────────────────────────
const onOrderStatusChanged_1 = require("./onOrderStatusChanged");
// The export is the raw handler function due to our mock of onDocumentUpdated
const handler = onOrderStatusChanged_1.onOrderStatusChanged;
// ── Test helpers ─────────────────────────────────────────────────────────────
function createEvent(beforeData, afterData, orderId = "order-123") {
    return {
        params: { orderId },
        data: {
            before: { data: () => beforeData },
            after: { data: () => afterData },
        },
    };
}
function setupUserDoc(options = {}) {
    const { exists = true, fcmToken = "fcm-token-123", notificationsEnabled = true, coins = 100, } = options;
    mockGet.mockResolvedValue({
        exists,
        data: () => exists
            ? {
                fcmToken,
                coins,
                preferences: { notificationsEnabled },
            }
            : undefined,
    });
}
// ── Tests ────────────────────────────────────────────────────────────────────
describe("onOrderStatusChanged", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        setupUserDoc();
    });
    describe("status change detection", () => {
        it("does nothing when status has not changed", async () => {
            const event = createEvent({ status: "confirmed", uid: "user-1" }, { status: "confirmed", uid: "user-1" });
            await handler(event);
            expect(mockAdd).not.toHaveBeenCalled();
            expect(mockSend).not.toHaveBeenCalled();
        });
        it("does nothing when event data is missing", async () => {
            const event = { params: { orderId: "order-123" }, data: null };
            await handler(event);
            expect(mockAdd).not.toHaveBeenCalled();
        });
    });
    describe("TrackingUpdate creation", () => {
        it("creates a TrackingUpdate record when status changes", async () => {
            const event = createEvent({ status: "pending", uid: "user-1" }, { status: "confirmed", uid: "user-1" });
            await handler(event);
            // Should call collection for trackingUpdates
            expect(mockCollection).toHaveBeenCalledWith("orders");
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({
                status: "confirmed",
                timestamp: "SERVER_TIMESTAMP",
            }));
        });
        it("includes note in TrackingUpdate when failureReason is present", async () => {
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "failed", uid: "user-1", failureReason: "Address not found" });
            await handler(event);
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({
                status: "failed",
                note: "Address not found",
                timestamp: "SERVER_TIMESTAMP",
            }));
        });
    });
    describe("FCM push notifications", () => {
        it("sends push notification when notifications are enabled", async () => {
            setupUserDoc({ notificationsEnabled: true });
            const event = createEvent({ status: "preparing", uid: "user-1" }, { status: "out_for_delivery", uid: "user-1", etaMinutes: 15 });
            await handler(event);
            expect(mockSend).toHaveBeenCalledWith(expect.objectContaining({
                token: "fcm-token-123",
                notification: {
                    title: "Your order is on the way!",
                    body: "ETA: 15 minutes",
                },
            }));
        });
        it("skips notification when user has notifications disabled", async () => {
            setupUserDoc({ notificationsEnabled: false });
            const event = createEvent({ status: "pending", uid: "user-1" }, { status: "confirmed", uid: "user-1" });
            await handler(event);
            expect(mockSend).not.toHaveBeenCalled();
        });
        it("skips notification when user has no FCM token", async () => {
            setupUserDoc({ fcmToken: null });
            const event = createEvent({ status: "pending", uid: "user-1" }, { status: "confirmed", uid: "user-1" });
            await handler(event);
            expect(mockSend).not.toHaveBeenCalled();
        });
        it("skips notification when user document does not exist", async () => {
            setupUserDoc({ exists: false });
            const event = createEvent({ status: "pending", uid: "user-1" }, { status: "confirmed", uid: "user-1" });
            await handler(event);
            expect(mockSend).not.toHaveBeenCalled();
        });
        it("sends delivered notification payload", async () => {
            setupUserDoc();
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "delivered", uid: "user-1", total: 5000 });
            await handler(event);
            expect(mockSend).toHaveBeenCalledWith(expect.objectContaining({
                notification: {
                    title: "Order delivered!",
                    body: "Tap to rate your experience",
                },
            }));
        });
        it("sends failed notification payload", async () => {
            setupUserDoc();
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "failed", uid: "user-1", failureReason: "Address not found" });
            await handler(event);
            expect(mockSend).toHaveBeenCalledWith(expect.objectContaining({
                notification: {
                    title: "Delivery issue",
                    body: "We couldn't deliver your order. We'll contact you shortly.",
                },
            }));
        });
    });
    describe("delivered status — leaderboard and coins", () => {
        it("updates leaderboard on delivered status", async () => {
            setupUserDoc();
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "delivered", uid: "user-1", total: 10000 });
            await handler(event);
            expect(mockSet).toHaveBeenCalledWith(expect.objectContaining({
                uid: "user-1",
                deliveries: { _increment: 1 },
                totalSpent: { _increment: 10000 },
                updatedAt: "SERVER_TIMESTAMP",
            }), { merge: true });
        });
        it("credits coins (5% of total) on delivered status", async () => {
            setupUserDoc();
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "delivered", uid: "user-1", total: 10000 });
            await handler(event);
            // 5% of 10000 = 500 coins
            expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({
                coins: { _increment: 500 },
            }));
        });
        it("records delivery timestamp on delivered", async () => {
            setupUserDoc();
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "delivered", uid: "user-1", total: 5000 });
            await handler(event);
            expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({
                deliveredAt: "SERVER_TIMESTAMP",
            }));
        });
        it("uses totalAmount field as fallback for total", async () => {
            setupUserDoc();
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "delivered", uid: "user-1", totalAmount: 8000 });
            await handler(event);
            // 5% of 8000 = 400 coins
            expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({
                coins: { _increment: 400 },
            }));
        });
    });
    describe("failed status — admin follow-up", () => {
        it("creates admin follow-up flag on failed status", async () => {
            setupUserDoc();
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "failed", uid: "user-1", failureReason: "Customer unavailable" });
            await handler(event);
            expect(mockCollection).toHaveBeenCalledWith("adminFollowUps");
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({
                orderId: "order-123",
                uid: "user-1",
                reason: "Customer unavailable",
                status: "pending",
                createdAt: "SERVER_TIMESTAMP",
            }));
        });
        it("uses default reason when failureReason is not provided", async () => {
            setupUserDoc();
            const event = createEvent({ status: "out_for_delivery", uid: "user-1" }, { status: "failed", uid: "user-1" });
            await handler(event);
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({
                reason: "Delivery failed — no reason provided",
            }));
        });
    });
});
//# sourceMappingURL=onOrderStatusChanged.test.js.map