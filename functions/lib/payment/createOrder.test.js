"use strict";
/**
 * Unit tests for createOrder Cloud Function.
 *
 * Validates:
 * - Req 2 AC2: Order_Service SHALL create a new Order from Cart summary with unique Order ID
 * - Req 6 AC4: Idempotency — processing same request twice SHALL NOT create duplicate Orders
 */
Object.defineProperty(exports, "__esModule", { value: true });
// ── Mocks ─────────────────────────────────────────────────────────────────────
const mockAdd = jest.fn();
const mockUpdate = jest.fn();
const mockTransactionDocGet = jest.fn();
const mockUserDocGet = jest.fn();
const mockCartDocGet = jest.fn();
const mockSnapshotDocGet = jest.fn();
// Track which collection/doc path is being accessed
let docPathTracker = [];
const mockDoc = jest.fn((id) => {
    docPathTracker.push(id);
    return {
        get: jest.fn(() => {
            // Route to appropriate mock based on context
            const lastCollection = collectionPathTracker[collectionPathTracker.length - 1];
            if (lastCollection === "transactions") {
                return mockTransactionDocGet();
            }
            else if (lastCollection === "users") {
                return mockUserDocGet();
            }
            else if (lastCollection === "carts") {
                return mockCartDocGet();
            }
            return mockTransactionDocGet();
        }),
        update: mockUpdate,
        collection: jest.fn((subCollection) => ({
            doc: jest.fn(() => ({
                get: mockSnapshotDocGet,
            })),
        })),
    };
});
let collectionPathTracker = [];
const mockCollection = jest.fn((path) => {
    collectionPathTracker.push(path);
    return {
        add: mockAdd,
        doc: mockDoc,
    };
});
const mockFirestore = Object.assign(jest.fn(() => ({
    collection: mockCollection,
})), {
    FieldValue: {
        serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
        increment: jest.fn((n) => `INCREMENT_${n}`),
    },
});
jest.mock("firebase-admin", () => ({
    firestore: mockFirestore,
    apps: [true],
    initializeApp: jest.fn(),
}));
const mockLoggerInfo = jest.fn();
const mockLoggerWarn = jest.fn();
const mockLoggerError = jest.fn();
jest.mock("firebase-functions", () => ({
    logger: {
        info: mockLoggerInfo,
        warn: mockLoggerWarn,
        error: mockLoggerError,
    },
}));
// Mock firebase-functions/v2/https
jest.mock("firebase-functions/v2/https", () => ({
    onCall: (handler) => handler,
    HttpsError: class HttpsError extends Error {
        constructor(code, message) {
            super(message);
            this.code = code;
            this.name = "HttpsError";
        }
    },
}));
// Import AFTER mocks
const createOrder_1 = require("./createOrder");
// ── Helpers ───────────────────────────────────────────────────────────────────
function createRequest(data, auth) {
    return { data, auth };
}
function setupTransactionMock(options = {}) {
    const { exists = true, status = "success", uid = "user-456", amount = 2000, orderId = null, } = options;
    mockTransactionDocGet.mockResolvedValue({
        exists,
        data: () => exists ? { uid, amount, status, orderId } : undefined,
    });
}
function setupUserMock(options = {}) {
    const { exists = true, role = "user" } = options;
    mockUserDocGet.mockResolvedValue({
        exists,
        data: () => exists ? { role } : undefined,
    });
}
function setupCartSnapshotMock(options = {}) {
    const { exists = true, items = [{ name: "Meal A", price: 1000, quantity: 2 }], } = options;
    mockSnapshotDocGet.mockResolvedValue({
        exists,
        data: () => exists ? { items } : undefined,
    });
}
function setupCartFallbackMock(options = {}) {
    const { exists = true, items = [{ name: "Meal B", price: 500, quantity: 1 }], } = options;
    mockCartDocGet.mockResolvedValue({
        exists,
        data: () => exists ? { items } : undefined,
    });
}
// ── Tests ─────────────────────────────────────────────────────────────────────
describe("createOrder", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        docPathTracker = [];
        collectionPathTracker = [];
        mockAdd.mockResolvedValue({ id: "order-new-456" });
        mockUpdate.mockResolvedValue(undefined);
    });
    // ── Authentication ────────────────────────────────────────────────────────
    describe("authentication", () => {
        it("throws unauthenticated error when no auth context", async () => {
            const request = createRequest({ transactionId: "txn-123" });
            await expect(createOrder_1.createOrder(request)).rejects.toMatchObject({
                code: "unauthenticated",
            });
        });
        it("throws invalid-argument when transactionId is missing", async () => {
            const request = createRequest({}, { uid: "user-456" });
            await expect(createOrder_1.createOrder(request)).rejects.toMatchObject({
                code: "invalid-argument",
            });
        });
        it("throws invalid-argument when transactionId is not a string", async () => {
            const request = createRequest({ transactionId: 123 }, { uid: "user-456" });
            await expect(createOrder_1.createOrder(request)).rejects.toMatchObject({
                code: "invalid-argument",
            });
        });
    });
    // ── Transaction validation ────────────────────────────────────────────────
    describe("transaction validation", () => {
        it("throws not-found when transaction does not exist", async () => {
            setupTransactionMock({ exists: false });
            const request = createRequest({ transactionId: "txn-missing" }, { uid: "user-456" });
            await expect(createOrder_1.createOrder(request)).rejects.toMatchObject({
                code: "not-found",
            });
        });
        it("throws permission-denied when caller is not the transaction owner and not admin", async () => {
            setupTransactionMock({ uid: "other-user" });
            setupUserMock({ role: "user" });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await expect(createOrder_1.createOrder(request)).rejects.toMatchObject({
                code: "permission-denied",
            });
        });
        it("allows admin to create order for another user's transaction", async () => {
            setupTransactionMock({ uid: "other-user", amount: 3000 });
            setupUserMock({ role: "admin" });
            setupCartSnapshotMock();
            const request = createRequest({ transactionId: "txn-123" }, { uid: "admin-user" });
            const result = await createOrder_1.createOrder(request);
            expect(result).toEqual({ orderId: "order-new-456" });
        });
        it("throws failed-precondition when transaction status is not success", async () => {
            setupTransactionMock({ status: "pending" });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await expect(createOrder_1.createOrder(request)).rejects.toMatchObject({
                code: "failed-precondition",
            });
        });
        it("throws failed-precondition for failed transactions", async () => {
            setupTransactionMock({ status: "failed" });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await expect(createOrder_1.createOrder(request)).rejects.toMatchObject({
                code: "failed-precondition",
            });
        });
    });
    // ── Idempotency ───────────────────────────────────────────────────────────
    describe("idempotency", () => {
        it("returns existing orderId if order already created for transaction", async () => {
            setupTransactionMock({ orderId: "existing-order-789" });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            const result = await createOrder_1.createOrder(request);
            expect(result).toEqual({ orderId: "existing-order-789" });
            expect(mockAdd).not.toHaveBeenCalled();
        });
        it("logs idempotent return", async () => {
            setupTransactionMock({ orderId: "existing-order-789" });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await createOrder_1.createOrder(request);
            expect(mockLoggerInfo).toHaveBeenCalledWith("Order already exists for transaction (idempotent return)", expect.objectContaining({
                transactionId: "txn-123",
                orderId: "existing-order-789",
            }));
        });
    });
    // ── Order creation ────────────────────────────────────────────────────────
    describe("order creation", () => {
        it("creates order from cart snapshot with correct fields", async () => {
            const items = [{ name: "Meal A", price: 1000, quantity: 2 }];
            setupTransactionMock({ amount: 2000 });
            setupCartSnapshotMock({ items });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await createOrder_1.createOrder(request);
            expect(mockCollection).toHaveBeenCalledWith("orders");
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({
                uid: "user-456",
                items,
                totalAmount: 2000,
                status: "confirmed",
                transactionId: "txn-123",
                createdAt: "SERVER_TIMESTAMP",
                updatedAt: "SERVER_TIMESTAMP",
            }));
        });
        it("returns the created orderId", async () => {
            setupTransactionMock();
            setupCartSnapshotMock();
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            const result = await createOrder_1.createOrder(request);
            expect(result).toEqual({ orderId: "order-new-456" });
        });
        it("links orderId back to the transaction document", async () => {
            setupTransactionMock();
            setupCartSnapshotMock();
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await createOrder_1.createOrder(request);
            expect(mockUpdate).toHaveBeenCalledWith(expect.objectContaining({
                orderId: "order-new-456",
                updatedAt: "SERVER_TIMESTAMP",
            }));
        });
        it("falls back to current cart when snapshot is missing", async () => {
            setupTransactionMock();
            setupCartSnapshotMock({ exists: false });
            setupCartFallbackMock({ items: [{ name: "Fallback Meal", price: 800, quantity: 1 }] });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await createOrder_1.createOrder(request);
            expect(mockLoggerWarn).toHaveBeenCalledWith("Cart snapshot not found, using current cart", expect.objectContaining({ transactionId: "txn-123" }));
        });
        it("creates order with empty items when neither snapshot nor cart exists", async () => {
            setupTransactionMock();
            setupCartSnapshotMock({ exists: false });
            setupCartFallbackMock({ exists: false });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await createOrder_1.createOrder(request);
            expect(mockAdd).toHaveBeenCalledWith(expect.objectContaining({
                items: [],
            }));
        });
        it("logs order creation with details", async () => {
            setupTransactionMock({ amount: 5000 });
            setupCartSnapshotMock({ items: [{ name: "A" }, { name: "B" }] });
            const request = createRequest({ transactionId: "txn-123" }, { uid: "user-456" });
            await createOrder_1.createOrder(request);
            expect(mockLoggerInfo).toHaveBeenCalledWith("Order created via createOrder callable", expect.objectContaining({
                orderId: "order-new-456",
                transactionId: "txn-123",
                uid: "user-456",
                totalAmount: 5000,
                itemCount: 2,
            }));
        });
    });
});
//# sourceMappingURL=createOrder.test.js.map