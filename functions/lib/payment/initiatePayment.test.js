"use strict";
/**
 * Unit tests for initiatePayment Cloud Function.
 *
 * Validates: Requirements 1.1, 1.3, 1.4, 6.2, 6.3
 *
 * Covers:
 *  - Authentication enforcement (unauthenticated users rejected)
 *  - Input validation (amount, phoneNumber)
 *  - UUID reference generation (unique, non-guessable)
 *  - Transaction creation in Firestore with status `pending`
 *  - Orange Money API call with correct payload
 *  - Error handling when Orange Money API fails
 *  - Return value contains transactionId and reference
 */
Object.defineProperty(exports, "__esModule", { value: true });
// ── Mocks ─────────────────────────────────────────────────────────────────────
const mockAdd = jest.fn();
const mockUpdate = jest.fn().mockResolvedValue(undefined);
const mockSet = jest.fn().mockResolvedValue(undefined);
// Subcollection mock: db.collection("transactions").doc(id).collection("cartSnapshot").doc("items").set(...)
const mockSubDoc = jest.fn(() => ({ set: mockSet }));
const mockSubCollection = jest.fn(() => ({ doc: mockSubDoc }));
const mockDoc = jest.fn(() => ({ collection: mockSubCollection, update: mockUpdate }));
const mockCollection = jest.fn(() => ({ add: mockAdd, doc: mockDoc }));
const mockFirestore = Object.assign(jest.fn(() => ({ collection: mockCollection })), {
    FieldValue: { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") },
});
jest.mock("firebase-admin", () => ({
    firestore: mockFirestore,
    apps: [true],
    initializeApp: jest.fn(),
}));
// Mock uuid
const mockUuid = "550e8400-e29b-41d4-a716-446655440000";
jest.mock("uuid", () => ({
    v4: () => mockUuid,
}));
// Mock firebase-functions logger
jest.mock("firebase-functions", () => ({
    logger: {
        info: jest.fn(),
        error: jest.fn(),
    },
}));
// Mock defineSecret
const mockSecretValues = {
    ORANGE_MONEY_API_KEY: "test-api-key-secret",
    ORANGE_MONEY_BASE_URL: "https://api.orangemoney.ml",
    ORANGE_MONEY_CALLBACK_URL: "https://us-central1-akka-food.cloudfunctions.net/orangeMoneyCallback",
};
jest.mock("firebase-functions/params", () => ({
    defineSecret: (name) => ({
        value: () => mockSecretValues[name] || "",
    }),
}));
// Mock global fetch
const mockFetch = jest.fn();
global.fetch = mockFetch;
// Mock onCall to extract the handler (ignore options object)
let capturedHandler;
jest.mock("firebase-functions/v2/https", () => ({
    onCall: (optionsOrHandler, handler) => {
        // onCall can be called with (options, handler) or (handler)
        if (typeof optionsOrHandler === "function") {
            capturedHandler = optionsOrHandler;
        }
        else if (handler) {
            capturedHandler = handler;
        }
        return capturedHandler;
    },
    HttpsError: class HttpsError extends Error {
        constructor(code, message) {
            super(message);
            this.code = code;
        }
    },
}));
// Import AFTER mocks
require("../payment/initiatePayment");
// ── Helpers ───────────────────────────────────────────────────────────────────
function makeRequest(data, auth) {
    return {
        auth: auth || null,
        data,
    };
}
// ── Tests ─────────────────────────────────────────────────────────────────────
describe("initiatePayment", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        // Default: Firestore add returns a doc ref with an id
        mockAdd.mockResolvedValue({ id: "txn-123", update: mockUpdate });
        mockSet.mockResolvedValue(undefined);
    });
    // ── Authentication ──────────────────────────────────────────────────────────
    describe("authentication", () => {
        it("throws unauthenticated when no auth token is provided", async () => {
            await expect(capturedHandler(makeRequest({ amount: 2000, phoneNumber: "70123456" }))).rejects.toMatchObject({ code: "unauthenticated" });
        });
        it("throws unauthenticated when auth is null", async () => {
            await expect(capturedHandler({ auth: null, data: { amount: 2000, phoneNumber: "70123456" } })).rejects.toMatchObject({ code: "unauthenticated" });
        });
    });
    // ── Input validation ────────────────────────────────────────────────────────
    describe("input validation", () => {
        it("throws invalid-argument when amount is missing", async () => {
            await expect(capturedHandler(makeRequest({ phoneNumber: "70123456" }, { uid: "user-1" }))).rejects.toMatchObject({ code: "invalid-argument" });
        });
        it("throws invalid-argument when amount is zero", async () => {
            await expect(capturedHandler(makeRequest({ amount: 0, phoneNumber: "70123456" }, { uid: "user-1" }))).rejects.toMatchObject({ code: "invalid-argument" });
        });
        it("throws invalid-argument when amount is negative", async () => {
            await expect(capturedHandler(makeRequest({ amount: -500, phoneNumber: "70123456" }, { uid: "user-1" }))).rejects.toMatchObject({ code: "invalid-argument" });
        });
        it("throws invalid-argument when amount is not an integer", async () => {
            await expect(capturedHandler(makeRequest({ amount: 1500.5, phoneNumber: "70123456" }, { uid: "user-1" }))).rejects.toMatchObject({ code: "invalid-argument" });
        });
        it("throws invalid-argument when phoneNumber is missing", async () => {
            await expect(capturedHandler(makeRequest({ amount: 2000 }, { uid: "user-1" }))).rejects.toMatchObject({ code: "invalid-argument" });
        });
        it("throws invalid-argument when phoneNumber is invalid format", async () => {
            await expect(capturedHandler(makeRequest({ amount: 2000, phoneNumber: "123" }, { uid: "user-1" }))).rejects.toMatchObject({ code: "invalid-argument" });
        });
        it("accepts a valid 8-digit Mali phone number", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            const result = await capturedHandler(makeRequest({ amount: 2000, phoneNumber: "70123456" }, { uid: "user-1" }));
            expect(result).toHaveProperty("transactionId");
        });
        it("accepts a phone number with +223 prefix", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            const result = await capturedHandler(makeRequest({ amount: 2000, phoneNumber: "+22370123456" }, { uid: "user-1" }));
            expect(result).toHaveProperty("transactionId");
        });
        it("accepts a phone number with 223 prefix (no plus)", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            const result = await capturedHandler(makeRequest({ amount: 2000, phoneNumber: "22370123456" }, { uid: "user-1" }));
            expect(result).toHaveProperty("transactionId");
        });
    });
    // ── Transaction creation (Req 1.3) ─────────────────────────────────────────
    describe("transaction creation", () => {
        it("creates a transaction document in Firestore with status pending", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            await capturedHandler(makeRequest({ amount: 3000, phoneNumber: "70123456" }, { uid: "user-1" }));
            expect(mockCollection).toHaveBeenCalledWith("transactions");
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({
                reference: mockUuid,
                uid: "user-1",
                amount: 3000,
                status: "pending",
                createdAt: "SERVER_TIMESTAMP",
                updatedAt: "SERVER_TIMESTAMP",
            }));
        });
        it("includes orderId when provided", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            await capturedHandler(makeRequest({ amount: 3000, phoneNumber: "70123456", orderId: "order-abc" }, { uid: "user-1" }));
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({ orderId: "order-abc" }));
        });
        it("sets orderId to null when not provided", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            await capturedHandler(makeRequest({ amount: 3000, phoneNumber: "70123456" }, { uid: "user-1" }));
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({ orderId: null }));
        });
    });
    // ── UUID reference generation (Req 1.4) ────────────────────────────────────
    describe("reference generation", () => {
        it("generates a UUID v4 reference and returns it", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            const result = await capturedHandler(makeRequest({ amount: 2000, phoneNumber: "70123456" }, { uid: "user-1" }));
            expect(result.reference).toBe(mockUuid);
        });
    });
    // ── Orange Money API call (Req 1.1, 6.2) ───────────────────────────────────
    describe("Orange Money API call", () => {
        it("calls the Orange Money API with correct payload", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            await capturedHandler(makeRequest({ amount: 5000, phoneNumber: "70123456" }, { uid: "user-1" }));
            expect(mockFetch).toHaveBeenCalledWith("https://api.orangemoney.ml/payment", expect.objectContaining({
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer test-api-key-secret",
                },
                body: JSON.stringify({
                    amount: 5000,
                    reference: mockUuid,
                    phoneNumber: "70123456",
                    callbackUrl: "https://us-central1-akka-food.cloudfunctions.net/orangeMoneyCallback",
                }),
            }));
        });
        it("marks transaction as failed when API returns non-OK response", async () => {
            mockFetch.mockResolvedValueOnce({
                ok: false,
                status: 400,
                text: async () => "Bad Request",
            });
            await expect(capturedHandler(makeRequest({ amount: 2000, phoneNumber: "70123456" }, { uid: "user-1" }))).rejects.toMatchObject({ code: "internal" });
            expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({ status: "failed" }));
        });
        it("marks transaction as failed on network error", async () => {
            mockFetch.mockRejectedValueOnce(new Error("Network timeout"));
            await expect(capturedHandler(makeRequest({ amount: 2000, phoneNumber: "70123456" }, { uid: "user-1" }))).rejects.toMatchObject({ code: "internal" });
            expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({ status: "failed" }));
        });
    });
    // ── Return value ────────────────────────────────────────────────────────────
    describe("return value", () => {
        it("returns transactionId and reference on success", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            const result = await capturedHandler(makeRequest({ amount: 2000, phoneNumber: "70123456" }, { uid: "user-1" }));
            expect(result).toEqual({
                transactionId: "txn-123",
                reference: mockUuid,
            });
        });
    });
    // ── Cart snapshot saving (Task 6.2) ─────────────────────────────────────────
    describe("cart snapshot saving", () => {
        const cartItems = [
            { mealId: "meal-1", mealName: "Riz au gras", unitPrice: 1500, quantity: 2 },
            { mealId: "meal-2", mealName: "Jus de bissap", unitPrice: 500, quantity: 1 },
        ];
        it("saves cart snapshot to subcollection when cartItems are provided", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            await capturedHandler(makeRequest({
                amount: 3500,
                phoneNumber: "70123456",
                cartItems,
                subtotal: 3500,
                deliveryFee: 500,
                discount: 0,
                redeemedCoins: 0,
            }, { uid: "user-1" }));
            // Verify the subcollection chain was called
            expect(mockCollection).toHaveBeenCalledWith("transactions");
            expect(mockDoc).toHaveBeenCalledWith("txn-123");
            expect(mockSubCollection).toHaveBeenCalledWith("cartSnapshot");
            expect(mockSubDoc).toHaveBeenCalledWith("items");
            expect(mockSet).toHaveBeenCalledWith(expect.objectContaining({
                items: [
                    { mealId: "meal-1", mealName: "Riz au gras", unitPrice: 1500, quantity: 2 },
                    { mealId: "meal-2", mealName: "Jus de bissap", unitPrice: 500, quantity: 1 },
                ],
                subtotal: 3500,
                deliveryFee: 500,
                discount: 0,
                total: 3500,
                redeemedCoins: 0,
                savedAt: "SERVER_TIMESTAMP",
            }));
        });
        it("does not save cart snapshot when cartItems is not provided", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            await capturedHandler(makeRequest({ amount: 2000, phoneNumber: "70123456" }, { uid: "user-1" }));
            expect(mockSet).not.toHaveBeenCalled();
        });
        it("does not save cart snapshot when cartItems is empty", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            await capturedHandler(makeRequest({ amount: 2000, phoneNumber: "70123456", cartItems: [] }, { uid: "user-1" }));
            expect(mockSet).not.toHaveBeenCalled();
        });
        it("uses amount as subtotal fallback when subtotal is not provided", async () => {
            mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });
            await capturedHandler(makeRequest({ amount: 3000, phoneNumber: "70123456", cartItems }, { uid: "user-1" }));
            expect(mockSet).toHaveBeenCalledWith(expect.objectContaining({
                subtotal: 3000,
                deliveryFee: 0,
                discount: 0,
                redeemedCoins: 0,
            }));
        });
    });
});
//# sourceMappingURL=initiatePayment.test.js.map