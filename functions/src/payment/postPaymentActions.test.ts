/**
 * Unit tests for postPaymentActions module.
 *
 * Validates:
 * - Req 2 AC2: Create Order from cart snapshot
 * - Req 2 AC3: Credit coins (5% of amount, rounded down)
 * - Req 2 AC4: Clear user's cart
 * - Req 2 AC6: Send FCM push notification
 */

// ── Mocks ─────────────────────────────────────────────────────────────────────

const mockAdd = jest.fn();
const mockUpdate = jest.fn();
const mockDelete = jest.fn();
const mockDocGet = jest.fn();
const mockSubcollectionDocGet = jest.fn();
const mockMessagingSend = jest.fn();

const mockDoc = jest.fn((path: string) => ({
  get: mockDocGet,
  update: mockUpdate,
  delete: mockDelete,
  collection: jest.fn(() => ({
    doc: jest.fn(() => ({
      get: mockSubcollectionDocGet,
    })),
  })),
}));

const mockCollection = jest.fn(() => ({
  add: mockAdd,
  doc: mockDoc,
}));

const mockFirestore = Object.assign(jest.fn(() => ({
  collection: mockCollection,
})), {
  FieldValue: {
    serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
    increment: jest.fn((n: number) => `INCREMENT_${n}`),
  },
});

jest.mock("firebase-admin", () => ({
  firestore: mockFirestore,
  apps: [true],
  initializeApp: jest.fn(),
  messaging: jest.fn(() => ({
    send: mockMessagingSend,
  })),
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

// Import AFTER mocks
import { calculateCoins, executePostPaymentActions, PostPaymentParams } from "./postPaymentActions";

// ── Helpers ───────────────────────────────────────────────────────────────────

const defaultParams: PostPaymentParams = {
  transactionId: "txn-123",
  uid: "user-456",
  amount: 2000,
  reference: "ref-789",
};

function setupMocks(options: {
  cartSnapshotExists?: boolean;
  cartItems?: unknown[];
  cartDocExists?: boolean;
  userExists?: boolean;
  fcmToken?: string | null;
} = {}) {
  const {
    cartSnapshotExists = true,
    cartItems = [{ name: "Meal A", price: 1000, quantity: 2 }],
    cartDocExists = true,
    userExists = true,
    fcmToken = "fcm-token-abc",
  } = options;

  // Cart snapshot subcollection
  mockSubcollectionDocGet.mockResolvedValue({
    exists: cartSnapshotExists,
    data: () => (cartSnapshotExists ? { items: cartItems } : undefined),
  });

  // Order creation
  mockAdd.mockResolvedValue({ id: "order-new-123" });

  // Transaction update (for orderId linking)
  mockUpdate.mockResolvedValue(undefined);

  // Cart delete
  mockDelete.mockResolvedValue(undefined);

  // User doc (for FCM token and cart fallback)
  mockDocGet.mockImplementation(() => {
    // This is called for both users/{uid} and carts/{uid}
    // We need to differentiate based on call order
    return Promise.resolve({
      exists: userExists,
      data: () => (userExists ? { fcmToken, coins: 50 } : undefined),
    });
  });

  // If cart snapshot doesn't exist, the fallback reads from carts collection
  if (!cartSnapshotExists) {
    mockDocGet.mockImplementation(() => {
      return Promise.resolve({
        exists: cartDocExists,
        data: () => (cartDocExists ? { items: cartItems } : undefined),
      });
    });
  }

  // FCM send
  mockMessagingSend.mockResolvedValue("message-id-123");
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("postPaymentActions", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── calculateCoins ──────────────────────────────────────────────────────────

  describe("calculateCoins", () => {
    it("returns 5% of amount rounded down", () => {
      expect(calculateCoins(2000)).toBe(100);
    });

    it("rounds down fractional coins", () => {
      expect(calculateCoins(1999)).toBe(99); // 1999 * 0.05 = 99.95 → 99
    });

    it("returns 0 for amounts less than 20", () => {
      expect(calculateCoins(19)).toBe(0); // 19 * 0.05 = 0.95 → 0
    });

    it("returns 0 for zero amount", () => {
      expect(calculateCoins(0)).toBe(0);
    });

    it("handles large amounts correctly", () => {
      expect(calculateCoins(100000)).toBe(5000);
    });

    it("returns 1 for minimum amount that earns a coin", () => {
      expect(calculateCoins(20)).toBe(1); // 20 * 0.05 = 1.0 → 1
    });
  });

  // ── executePostPaymentActions ───────────────────────────────────────────────

  describe("executePostPaymentActions", () => {
    it("creates an order document with correct fields", async () => {
      setupMocks();

      await executePostPaymentActions(defaultParams);

      expect(mockCollection).toHaveBeenCalledWith("orders");
      expect(mockAdd).toHaveBeenCalledWith(
        expect.objectContaining({
          uid: "user-456",
          totalAmount: 2000,
          status: "confirmed",
          transactionId: "txn-123",
          createdAt: "SERVER_TIMESTAMP",
          updatedAt: "SERVER_TIMESTAMP",
        })
      );
    });

    it("returns the created orderId", async () => {
      setupMocks();

      const result = await executePostPaymentActions(defaultParams);

      expect(result.orderId).toBe("order-new-123");
    });

    it("updates the transaction with the orderId", async () => {
      setupMocks();

      await executePostPaymentActions(defaultParams);

      // The transaction doc update for orderId
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          orderId: "order-new-123",
          updatedAt: "SERVER_TIMESTAMP",
        })
      );
    });

    it("does not directly credit coins (handled by onPaymentSuccess trigger)", async () => {
      setupMocks();

      await executePostPaymentActions(defaultParams);

      // Coin crediting is now handled by the onPaymentSuccess Firestore trigger
      // postPaymentActions no longer calls FieldValue.increment for coins
      expect(mockUpdate).not.toHaveBeenCalledWith(
        expect.objectContaining({
          coins: expect.anything(),
        })
      );
    });

    it("deletes the user cart document", async () => {
      setupMocks();

      await executePostPaymentActions(defaultParams);

      expect(mockDelete).toHaveBeenCalled();
    });

    it("sends FCM notification with order details", async () => {
      setupMocks();

      await executePostPaymentActions(defaultParams);

      expect(mockMessagingSend).toHaveBeenCalledWith(
        expect.objectContaining({
          token: "fcm-token-abc",
          notification: expect.objectContaining({
            title: "Commande confirmée 🎉",
          }),
          data: expect.objectContaining({
            type: "order_confirmed",
            orderId: "order-new-123",
            amount: "2000",
          }),
        })
      );
    });

    it("does not send FCM if user has no token", async () => {
      setupMocks({ fcmToken: null });

      await executePostPaymentActions(defaultParams);

      expect(mockMessagingSend).not.toHaveBeenCalled();
      expect(mockLoggerWarn).toHaveBeenCalledWith(
        "No FCM token found for user",
        expect.objectContaining({ uid: "user-456" })
      );
    });

    it("does not log coin credit messages (handled by onPaymentSuccess trigger)", async () => {
      setupMocks();

      await executePostPaymentActions({ ...defaultParams, amount: 10 });

      // Coin crediting is now handled by the onPaymentSuccess trigger,
      // so postPaymentActions no longer logs coin-related messages
      expect(mockLoggerInfo).not.toHaveBeenCalledWith(
        "No coins to credit (amount too small)",
        expect.anything()
      );
    });

    it("falls back to current cart when snapshot is missing", async () => {
      setupMocks({ cartSnapshotExists: false });

      await executePostPaymentActions(defaultParams);

      expect(mockLoggerWarn).toHaveBeenCalledWith(
        "Cart snapshot not found, using current cart",
        expect.objectContaining({ transactionId: "txn-123" })
      );
    });

    it("handles FCM send failure gracefully without throwing", async () => {
      setupMocks();
      mockMessagingSend.mockRejectedValue(new Error("FCM token expired"));

      // Should not throw
      const result = await executePostPaymentActions(defaultParams);

      expect(result.orderId).toBe("order-new-123");
      expect(mockLoggerError).toHaveBeenCalledWith(
        "Failed to send FCM notification",
        expect.objectContaining({
          error: "FCM token expired",
        })
      );
    });
  });
});
