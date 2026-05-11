"use strict";
/**
 * Unit tests for adminUpdateOrderStatus Cloud Function.
 *
 * Validates: Requirements 4.3, 4.5
 *
 * Covers:
 *  - Admin role enforcement (delegated to verifyAdmin, tested separately)
 *  - Required field validation (orderId, status)
 *  - ETA validation for out_for_delivery
 *  - Order existence check
 *  - Status transition validation (all valid and invalid transitions)
 *  - Push notification triggered on successful update (Req 4.3)
 */
Object.defineProperty(exports, "__esModule", { value: true });
// ── Mocks ─────────────────────────────────────────────────────────────────────
const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockGet = jest.fn();
const mockDoc = jest.fn(() => ({ get: mockGet, update: mockUpdate }));
const mockFirestore = Object.assign(jest.fn(() => ({ doc: mockDoc })), {
    FieldValue: { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") },
});
jest.mock("firebase-admin", () => ({
    firestore: mockFirestore,
    apps: [true],
    initializeApp: jest.fn(),
    messaging: jest.fn(),
}));
// Mock verifyAdmin to resolve (admin check passes) by default
jest.mock("../helpers/verifyAdmin", () => ({
    verifyAdmin: jest.fn().mockResolvedValue(undefined),
}));
// Mock sendOrderStatusNotification
const mockSendNotification = jest.fn().mockResolvedValue(undefined);
jest.mock("../helpers/sendOrderStatusNotification", () => ({
    sendOrderStatusNotification: mockSendNotification,
}));
// Mock onCall so we can extract and call the handler directly
let capturedHandler;
jest.mock("firebase-functions/v2/https", () => ({
    onCall: (handler) => {
        capturedHandler = handler;
        return handler;
    },
    HttpsError: class HttpsError extends Error {
        constructor(code, message) {
            super(message);
            this.code = code;
        }
    },
}));
// Import AFTER mocks
require("../admin/adminUpdateOrderStatus");
// ── Helpers ───────────────────────────────────────────────────────────────────
function makeRequest(data, uid = "admin-uid") {
    return {
        auth: { uid, token: {} },
        data,
    };
}
function makeOrderSnapshot(exists, data) {
    return {
        exists,
        data: () => data,
    };
}
// ── Tests ─────────────────────────────────────────────────────────────────────
describe("adminUpdateOrderStatus", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });
    // ── Field validation ────────────────────────────────────────────────────────
    it("throws invalid-argument when orderId is missing", async () => {
        await expect(capturedHandler(makeRequest({ status: "confirmed" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument when status is missing", async () => {
        await expect(capturedHandler(makeRequest({ orderId: "order-1" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument when status is not a recognised value", async () => {
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "flying" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument when status is out_for_delivery and etaMinutes is missing", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "ready_for_pickup", uid: "user-1" }));
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "out_for_delivery" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    // ── Order existence ─────────────────────────────────────────────────────────
    it("throws not-found when order does not exist", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(false));
        await expect(capturedHandler(makeRequest({ orderId: "ghost-order", status: "confirmed" }))).rejects.toMatchObject({ code: "not-found" });
    });
    // ── Transition validation ───────────────────────────────────────────────────
    const invalidTransitions = [
        ["pending", "preparing"],
        ["pending", "ready_for_pickup"],
        ["pending", "out_for_delivery"],
        ["pending", "delivered"],
        ["confirmed", "pending"],
        ["confirmed", "ready_for_pickup"],
        ["confirmed", "out_for_delivery"],
        ["confirmed", "delivered"],
        ["preparing", "pending"],
        ["preparing", "confirmed"],
        ["preparing", "out_for_delivery"],
        ["preparing", "delivered"],
        ["ready_for_pickup", "pending"],
        ["ready_for_pickup", "confirmed"],
        ["ready_for_pickup", "preparing"],
        ["out_for_delivery", "pending"],
        ["out_for_delivery", "confirmed"],
        ["out_for_delivery", "preparing"],
        ["out_for_delivery", "ready_for_pickup"],
        ["delivered", "confirmed"],
        ["delivered", "cancelled"],
        ["cancelled", "confirmed"],
        ["cancelled", "pending"],
    ];
    it.each(invalidTransitions)("throws failed-precondition for invalid transition %s → %s", async (from, to) => {
        const requestData = {
            orderId: "order-1",
            status: to,
        };
        // out_for_delivery requires etaMinutes
        if (to === "out_for_delivery")
            requestData["etaMinutes"] = 30;
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: from, uid: "user-1" }));
        await expect(capturedHandler(makeRequest(requestData))).rejects.toMatchObject({
            code: "failed-precondition",
            message: expect.stringContaining(`Invalid status transition from ${from} to ${to}`),
        });
    });
    const validTransitions = [
        ["pending", "confirmed"],
        ["pending", "cancelled"],
        ["confirmed", "preparing"],
        ["confirmed", "cancelled"],
        ["preparing", "ready_for_pickup"],
        ["preparing", "cancelled"],
        ["ready_for_pickup", "out_for_delivery", 20],
        ["ready_for_pickup", "delivered"],
        ["ready_for_pickup", "cancelled"],
        ["out_for_delivery", "delivered"],
        ["out_for_delivery", "cancelled"],
    ];
    it.each(validTransitions)("allows valid transition %s → %s", async (from, to, eta) => {
        const requestData = {
            orderId: "order-1",
            status: to,
        };
        if (eta !== undefined)
            requestData["etaMinutes"] = eta;
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: from, uid: "user-1" }));
        const result = await capturedHandler(makeRequest(requestData));
        expect(result).toEqual({ success: true });
        expect(mockUpdate).toHaveBeenCalledTimes(1);
    });
    // ── Notification (Requirement 4.3) ──────────────────────────────────────────
    it("sends a push notification to the customer on successful status update", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "confirmed", uid: "customer-uid" }));
        await capturedHandler(makeRequest({ orderId: "order-1", status: "preparing" }));
        expect(mockSendNotification).toHaveBeenCalledTimes(1);
        expect(mockSendNotification).toHaveBeenCalledWith("order-1", "customer-uid", "preparing", undefined);
    });
    it("sends etaMinutes in the notification for out_for_delivery", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "ready_for_pickup", uid: "customer-uid" }));
        await capturedHandler(makeRequest({ orderId: "order-1", status: "out_for_delivery", etaMinutes: 25 }));
        expect(mockSendNotification).toHaveBeenCalledWith("order-1", "customer-uid", "out_for_delivery", 25);
    });
    it("does not send a notification when the order has no uid", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "confirmed" }) // no uid field
        );
        await capturedHandler(makeRequest({ orderId: "order-1", status: "preparing" }));
        expect(mockSendNotification).not.toHaveBeenCalled();
    });
    // ── Firestore update ────────────────────────────────────────────────────────
    it("writes the new status and updatedAt to Firestore", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "pending", uid: "user-1" }));
        await capturedHandler(makeRequest({ orderId: "order-42", status: "confirmed" }));
        expect(mockDoc).toHaveBeenCalledWith("orders/order-42");
        expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({
            status: "confirmed",
            updatedAt: "SERVER_TIMESTAMP",
        }));
    });
    it("writes etaMinutes to Firestore when transitioning to out_for_delivery", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "ready_for_pickup", uid: "user-1" }));
        await capturedHandler(makeRequest({ orderId: "order-42", status: "out_for_delivery", etaMinutes: 15 }));
        expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({
            status: "out_for_delivery",
            etaMinutes: 15,
        }));
    });
});
//# sourceMappingURL=adminUpdateOrderStatus.test.js.map