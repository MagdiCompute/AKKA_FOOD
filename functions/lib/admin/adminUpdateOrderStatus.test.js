"use strict";
/**
 * Unit tests for adminUpdateOrderStatus Cloud Function.
 *
 * Validates: Requirements 4.1, 4.3, 4.5
 *
 * Covers:
 *  - Admin role enforcement (delegated to verifyAdmin helper)
 *  - Required field validation (orderId, status)
 *  - ETA validation for out_for_delivery
 *  - Order existence check
 *  - Status transition validation per design doc:
 *      pending → confirmed → preparing → out_for_delivery → delivered | failed
 *  - Push notification triggered on successful update
 *  - Firestore document update with correct fields
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
// Mock verifyAdmin — resolves by default (admin check passes)
const mockVerifyAdmin = jest.fn().mockResolvedValue(undefined);
jest.mock("../helpers/verifyAdmin", () => ({
    verifyAdmin: mockVerifyAdmin,
}));
// Mock sendOrderStatusNotification
const mockSendNotification = jest.fn().mockResolvedValue(undefined);
jest.mock("../helpers/sendOrderStatusNotification", () => ({
    sendOrderStatusNotification: mockSendNotification,
}));
// Mock onCall to capture the handler
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
// Import AFTER mocks are set up
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
        // Re-establish default implementations after clearAllMocks
        mockVerifyAdmin.mockResolvedValue(undefined);
        mockUpdate.mockResolvedValue(undefined);
        mockSendNotification.mockResolvedValue(undefined);
        mockDoc.mockImplementation(() => ({ get: mockGet, update: mockUpdate }));
        mockFirestore.mockImplementation(() => ({ doc: mockDoc }));
    });
    // ── Admin role validation ───────────────────────────────────────────────────
    it("calls verifyAdmin with the request auth context", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "pending", uid: "user-1" }));
        const auth = { uid: "admin-uid", token: {} };
        await capturedHandler({ auth, data: { orderId: "order-1", status: "confirmed" } });
        expect(mockVerifyAdmin).toHaveBeenCalledWith(auth);
    });
    it("rejects unauthenticated callers (verifyAdmin throws)", async () => {
        mockVerifyAdmin.mockRejectedValueOnce(Object.assign(new Error("The function must be called while authenticated."), {
            code: "unauthenticated",
        }));
        await expect(capturedHandler({ auth: undefined, data: { orderId: "order-1", status: "confirmed" } })).rejects.toMatchObject({ code: "unauthenticated" });
    });
    it("rejects non-admin callers (verifyAdmin throws permission-denied)", async () => {
        mockVerifyAdmin.mockRejectedValueOnce(Object.assign(new Error("Admins only"), { code: "permission-denied" }));
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "confirmed" }))).rejects.toMatchObject({ code: "permission-denied" });
    });
    // ── Field validation ────────────────────────────────────────────────────────
    it("throws invalid-argument when orderId is missing", async () => {
        await expect(capturedHandler(makeRequest({ status: "confirmed" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument when orderId is not a string", async () => {
        await expect(capturedHandler(makeRequest({ orderId: 123, status: "confirmed" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument when status is missing", async () => {
        await expect(capturedHandler(makeRequest({ orderId: "order-1" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument when status is not a recognised value", async () => {
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "flying" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument for statuses not in the valid set", async () => {
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "ready_for_pickup" }))).rejects.toMatchObject({ code: "invalid-argument" });
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "cancelled" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument when status is out_for_delivery and etaMinutes is missing", async () => {
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "out_for_delivery" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    it("throws invalid-argument when etaMinutes is not a number for out_for_delivery", async () => {
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "out_for_delivery", etaMinutes: "thirty" }))).rejects.toMatchObject({ code: "invalid-argument" });
    });
    // ── Order existence ─────────────────────────────────────────────────────────
    it("throws not-found when order does not exist", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(false));
        await expect(capturedHandler(makeRequest({ orderId: "ghost-order", status: "confirmed" }))).rejects.toMatchObject({ code: "not-found" });
    });
    // ── Status transition validation ────────────────────────────────────────────
    describe("valid transitions", () => {
        it("allows transition pending → confirmed", async () => {
            mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "pending", uid: "user-1" }));
            const result = await capturedHandler(makeRequest({ orderId: "order-1", status: "confirmed" }));
            expect(result).toEqual({ success: true });
            expect(mockUpdate).toHaveBeenCalledTimes(1);
        });
        it("allows transition confirmed → preparing", async () => {
            mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "confirmed", uid: "user-1" }));
            const result = await capturedHandler(makeRequest({ orderId: "order-1", status: "preparing" }));
            expect(result).toEqual({ success: true });
            expect(mockUpdate).toHaveBeenCalledTimes(1);
        });
        it("allows transition preparing → out_for_delivery (with etaMinutes)", async () => {
            mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "preparing", uid: "user-1" }));
            const result = await capturedHandler(makeRequest({ orderId: "order-1", status: "out_for_delivery", etaMinutes: 25 }));
            expect(result).toEqual({ success: true });
            expect(mockUpdate).toHaveBeenCalledTimes(1);
        });
        it("allows transition out_for_delivery → delivered", async () => {
            mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "out_for_delivery", uid: "user-1" }));
            const result = await capturedHandler(makeRequest({ orderId: "order-1", status: "delivered" }));
            expect(result).toEqual({ success: true });
            expect(mockUpdate).toHaveBeenCalledTimes(1);
        });
        it("allows transition out_for_delivery → failed", async () => {
            mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "out_for_delivery", uid: "user-1" }));
            const result = await capturedHandler(makeRequest({ orderId: "order-1", status: "failed" }));
            expect(result).toEqual({ success: true });
            expect(mockUpdate).toHaveBeenCalledTimes(1);
        });
    });
    describe("invalid transitions", () => {
        const invalidTransitions = [
            // pending can only go to confirmed
            ["pending", "preparing"],
            ["pending", "delivered"],
            ["pending", "failed"],
            // confirmed can only go to preparing
            ["confirmed", "pending"],
            ["confirmed", "delivered"],
            ["confirmed", "failed"],
            // preparing can only go to out_for_delivery
            ["preparing", "pending"],
            ["preparing", "confirmed"],
            ["preparing", "delivered"],
            ["preparing", "failed"],
            // out_for_delivery can only go to delivered or failed
            ["out_for_delivery", "pending"],
            ["out_for_delivery", "confirmed"],
            ["out_for_delivery", "preparing"],
            // terminal states have no outgoing transitions
            ["delivered", "pending"],
            ["delivered", "confirmed"],
            ["delivered", "preparing"],
            ["delivered", "failed"],
            ["failed", "pending"],
            ["failed", "confirmed"],
            ["failed", "preparing"],
            ["failed", "delivered"],
        ];
        it.each(invalidTransitions)("throws failed-precondition for %s → %s", async (from, to) => {
            const requestData = {
                orderId: "order-1",
                status: to,
            };
            // out_for_delivery requires etaMinutes (but won't reach that check for invalid transitions from terminal states)
            // However, we need to pass etaMinutes if `to` is out_for_delivery to get past the field validation
            if (to === "out_for_delivery")
                requestData["etaMinutes"] = 30;
            mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: from, uid: "user-1" }));
            await expect(capturedHandler(makeRequest(requestData))).rejects.toMatchObject({
                code: "failed-precondition",
                message: expect.stringContaining(`Invalid status transition from ${from} to ${to}`),
            });
        });
    });
    it("throws failed-precondition when current status is unrecognised", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "unknown_status", uid: "user-1" }));
        await expect(capturedHandler(makeRequest({ orderId: "order-1", status: "confirmed" }))).rejects.toMatchObject({ code: "failed-precondition" });
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
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "preparing", uid: "user-1" }));
        await capturedHandler(makeRequest({ orderId: "order-42", status: "out_for_delivery", etaMinutes: 15 }));
        expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({
            status: "out_for_delivery",
            etaMinutes: 15,
            updatedAt: "SERVER_TIMESTAMP",
        }));
    });
    it("does not write etaMinutes for non-out_for_delivery transitions", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "pending", uid: "user-1" }));
        await capturedHandler(makeRequest({ orderId: "order-1", status: "confirmed" }));
        const updateArg = mockUpdate.mock.calls[0][0];
        expect(updateArg).not.toHaveProperty("etaMinutes");
    });
    // ── Push notification ───────────────────────────────────────────────────────
    it("sends a push notification to the customer on successful status update", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "confirmed", uid: "customer-uid" }));
        await capturedHandler(makeRequest({ orderId: "order-1", status: "preparing" }));
        expect(mockSendNotification).toHaveBeenCalledTimes(1);
        expect(mockSendNotification).toHaveBeenCalledWith("order-1", "customer-uid", "preparing", undefined);
    });
    it("sends etaMinutes in the notification for out_for_delivery", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "preparing", uid: "customer-uid" }));
        await capturedHandler(makeRequest({ orderId: "order-1", status: "out_for_delivery", etaMinutes: 25 }));
        expect(mockSendNotification).toHaveBeenCalledWith("order-1", "customer-uid", "out_for_delivery", 25);
    });
    it("does not send a notification when the order has no uid", async () => {
        mockGet.mockResolvedValueOnce(makeOrderSnapshot(true, { status: "confirmed" }) // no uid field
        );
        await capturedHandler(makeRequest({ orderId: "order-1", status: "preparing" }));
        expect(mockSendNotification).not.toHaveBeenCalled();
    });
});
//# sourceMappingURL=adminUpdateOrderStatus.test.js.map