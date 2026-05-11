/**
 * Unit tests for onPaymentSuccess Cloud Function.
 *
 * Tests cover:
 * - Coin calculation: floor(amount * 0.05)
 * - Zero-cash order handling (no coins credited)
 * - Idempotency: duplicate orderId does not double-credit (pre-check + in-transaction guard)
 * - Atomic transaction: balance + CoinTransaction created together
 * - Race condition prevention: deterministic doc ID with in-transaction existence check
 */

// ── Mocks ─────────────────────────────────────────────────────────────────────

const mockTransactionGet = jest.fn();
const mockTransactionSet = jest.fn();
const mockTransactionUpdate = jest.fn();
const mockRunTransaction = jest.fn();
const mockQueryGet = jest.fn();

// Build a chainable mock for Firestore
function createMockFirestore() {
  const mockDocRef = { id: "new-coin-tx-id" };
  const mockDeterministicDocRef = { id: "reward_order-abc" };

  const mockSubCollection = {
    doc: jest.fn((docId?: string) => {
      if (docId && docId.startsWith("reward_")) {
        return mockDeterministicDocRef;
      }
      return mockDocRef;
    }),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnValue({ get: mockQueryGet }),
  };

  const mockUserDoc = {
    collection: jest.fn().mockReturnValue(mockSubCollection),
  };

  const mockUsersCollection = {
    doc: jest.fn().mockReturnValue(mockUserDoc),
  };

  const db = {
    doc: jest.fn().mockReturnValue(mockDocRef),
    collection: jest.fn().mockReturnValue(mockUsersCollection),
    runTransaction: mockRunTransaction,
  };

  return { db, mockSubCollection, mockUserDoc, mockUsersCollection, mockDocRef, mockDeterministicDocRef };
}

const { db: mockDb, mockDeterministicDocRef } = createMockFirestore();

jest.mock("firebase-admin", () => {
  const firestoreFn = () => mockDb;
  firestoreFn.FieldValue = {
    serverTimestamp: () => "SERVER_TIMESTAMP",
  };

  return {
    apps: [{}],
    initializeApp: jest.fn(),
    firestore: firestoreFn,
  };
});

jest.mock("firebase-functions", () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

jest.mock("firebase-functions/v2/firestore", () => ({
  onDocumentUpdated: jest.fn((_path: string, handler: unknown) => handler),
}));

// Import AFTER mocks
import { calculateCoins, onPaymentSuccess } from "./onPaymentSuccess";

// The handler is the function itself (since our mock returns the handler directly)
const handler = onPaymentSuccess as unknown as (event: unknown) => Promise<void>;

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("onPaymentSuccess", () => {
  beforeEach(() => {
    jest.clearAllMocks();

    // Default: no existing coin transaction (idempotency pre-check passes)
    mockQueryGet.mockResolvedValue({ empty: true });

    // Default: runTransaction executes the callback
    mockRunTransaction.mockImplementation(
      async (cb: (t: { get: jest.Mock; set: jest.Mock; update: jest.Mock }) => Promise<void>) => {
        await cb({
          get: mockTransactionGet,
          set: mockTransactionSet,
          update: mockTransactionUpdate,
        });
      }
    );

    // Default: deterministic doc does not exist (first call for this orderId)
    // and user has coinBalance of 500
    mockTransactionGet.mockImplementation((ref: unknown) => {
      if (ref === mockDeterministicDocRef) {
        return Promise.resolve({ exists: false, data: () => null });
      }
      // User document
      return Promise.resolve({ data: () => ({ coinBalance: 500 }) });
    });
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

    it("returns 1 for minimum amount that earns a coin (20 XOF)", () => {
      expect(calculateCoins(20)).toBe(1); // 20 * 0.05 = 1.0 → 1
    });

    it("returns 0 for amount = 19 (boundary below minimum earning)", () => {
      expect(calculateCoins(19)).toBe(0); // 19 * 0.05 = 0.95 → 0
    });

    it("handles very large amounts without overflow", () => {
      // 10,000,000 XOF order → 500,000 coins
      expect(calculateCoins(10000000)).toBe(500000);
    });

    it("returns correct coins for amount = 21 (just above boundary)", () => {
      expect(calculateCoins(21)).toBe(1); // 21 * 0.05 = 1.05 → 1
    });

    it("returns correct coins for amount = 39 (just below next coin)", () => {
      expect(calculateCoins(39)).toBe(1); // 39 * 0.05 = 1.95 → 1
    });

    it("returns correct coins for amount = 40 (exactly 2 coins)", () => {
      expect(calculateCoins(40)).toBe(2); // 40 * 0.05 = 2.0 → 2
    });
  });

  // ── Trigger logic ───────────────────────────────────────────────────────────

  describe("trigger handler", () => {
    function makeEvent(
      beforeStatus: string,
      afterStatus: string,
      afterData: Record<string, unknown> = {}
    ) {
      return {
        data: {
          before: { data: () => ({ status: beforeStatus }) },
          after: {
            data: () => ({
              status: afterStatus,
              uid: "user-123",
              amount: 2000,
              orderId: "order-abc",
              ...afterData,
            }),
          },
        },
        params: { transactionId: "tx-001" },
      };
    }

    it("does nothing if status did not change to success", async () => {
      const event = makeEvent("pending", "failed");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("does nothing if status was already success (no re-trigger)", async () => {
      const event = makeEvent("success", "success");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("does nothing if coins would be 0 (zero-cash order, Req 1 AC5)", async () => {
      // 10 * 0.05 = 0.5 → floor = 0
      const event = makeEvent("pending", "success", { amount: 10 });
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("does nothing if uid is missing", async () => {
      const event = {
        data: {
          before: { data: () => ({ status: "pending" }) },
          after: { data: () => ({ status: "success", amount: 2000 }) },
        },
        params: { transactionId: "tx-001" },
      };
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("does nothing if before/after data is missing", async () => {
      const event = { data: null, params: { transactionId: "tx-001" } };
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("skips if coin transaction with same orderId already exists in pre-check (idempotency, Req 1 AC3)", async () => {
      // Mock: existing coin transaction found in pre-check query
      mockQueryGet.mockResolvedValue({ empty: false });

      const event = makeEvent("pending", "success");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("skips crediting inside transaction if deterministic doc already exists (race condition guard, Req 1 AC3)", async () => {
      // Pre-check passes (empty), but inside the transaction the doc already exists
      // This simulates a race condition where another execution wrote between pre-check and transaction
      mockTransactionGet.mockImplementation((ref: unknown) => {
        if (ref === mockDeterministicDocRef) {
          return Promise.resolve({ exists: true, data: () => ({ amount: 100, orderId: "order-abc" }) });
        }
        return Promise.resolve({ data: () => ({ coinBalance: 500 }) });
      });

      const event = makeEvent("pending", "success");
      await handler(event);

      expect(mockRunTransaction).toHaveBeenCalledTimes(1);
      // Transaction ran but should NOT have called set or update (early return inside transaction)
      expect(mockTransactionSet).not.toHaveBeenCalled();
      expect(mockTransactionUpdate).not.toHaveBeenCalled();
    });

    it("credits coins via atomic transaction when all checks pass (Req 5 AC2)", async () => {
      const event = makeEvent("pending", "success", { amount: 2000 });
      await handler(event);

      expect(mockRunTransaction).toHaveBeenCalledTimes(1);
      // Verify CoinTransaction was created with deterministic doc ref
      expect(mockTransactionSet).toHaveBeenCalledWith(
        mockDeterministicDocRef,
        expect.objectContaining({
          amount: 100, // floor(2000 * 0.05) = 100
          reason: "Purchase reward",
          orderId: "order-abc",
          timestamp: "SERVER_TIMESTAMP",
        })
      );
      // Verify coinBalance was updated
      expect(mockTransactionUpdate).toHaveBeenCalledWith(
        expect.anything(),
        { coinBalance: 600 } // 500 + 100
      );
    });

    it("uses transactionId as orderId fallback when orderId is missing", async () => {
      const event = {
        data: {
          before: { data: () => ({ status: "pending" }) },
          after: {
            data: () => ({
              status: "success",
              uid: "user-123",
              amount: 2000,
              // no orderId field
            }),
          },
        },
        params: { transactionId: "tx-fallback" },
      };

      await handler(event);

      expect(mockRunTransaction).toHaveBeenCalledTimes(1);
      expect(mockTransactionSet).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          orderId: "tx-fallback",
        })
      );
    });

    it("initializes coinBalance to 0 if user has no existing balance", async () => {
      mockTransactionGet.mockImplementation((ref: unknown) => {
        if (ref === mockDeterministicDocRef) {
          return Promise.resolve({ exists: false, data: () => null });
        }
        return Promise.resolve({ data: () => ({}) }); // no coinBalance field
      });

      const event = makeEvent("pending", "success", { amount: 2000 });
      await handler(event);

      expect(mockTransactionUpdate).toHaveBeenCalledWith(
        expect.anything(),
        { coinBalance: 100 } // 0 + 100
      );
    });

    it("re-throws errors from the transaction for Cloud Functions retry", async () => {
      mockRunTransaction.mockRejectedValue(new Error("Firestore unavailable"));

      const event = makeEvent("pending", "success");
      await expect(handler(event)).rejects.toThrow("Firestore unavailable");
    });
  });
});
