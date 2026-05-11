/**
 * Unit tests for redeemCoins HTTPS Callable Cloud Function.
 *
 * Tests cover:
 * - Validation: redemption amount must be a positive multiple of 1000
 * - Authentication: unauthenticated users are rejected
 * - Balance check: insufficient coins returns error
 * - Atomic transaction: balance debit + CoinTransaction creation
 * - Balance never goes below 0
 */

// ── Mocks ─────────────────────────────────────────────────────────────────────

const mockTransactionGet = jest.fn();
const mockTransactionSet = jest.fn();
const mockTransactionUpdate = jest.fn();
const mockRunTransaction = jest.fn();

function createMockFirestore() {
  const mockDocRef = { id: "new-coin-tx-id" };

  const mockSubCollection = {
    doc: jest.fn().mockReturnValue(mockDocRef),
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

  return { db, mockDocRef };
}

const { db: mockDb } = createMockFirestore();

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

jest.mock("firebase-functions/v2/https", () => {
  class HttpsError extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
      this.name = "HttpsError";
    }
  }

  return {
    HttpsError,
    onCall: jest.fn((handler: unknown) => handler),
  };
});

// Import AFTER mocks
import { redeemCoins, validateRedemptionAmount } from "./redeemCoins";
import { HttpsError } from "firebase-functions/v2/https";

// The handler is the function itself (since our mock returns the handler directly)
const handler = redeemCoins as unknown as (request: {
  auth?: { uid: string };
  data: Record<string, unknown>;
}) => Promise<{ success: boolean }>;

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("redeemCoins", () => {
  beforeEach(() => {
    jest.clearAllMocks();

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

    // Default: user has coinBalance of 3000
    mockTransactionGet.mockResolvedValue({
      data: () => ({ coinBalance: 3000 }),
    });
  });

  // ── validateRedemptionAmount ────────────────────────────────────────────────

  describe("validateRedemptionAmount", () => {
    it("returns true for 1000", () => {
      expect(validateRedemptionAmount(1000)).toBe(true);
    });

    it("returns true for 2000", () => {
      expect(validateRedemptionAmount(2000)).toBe(true);
    });

    it("returns true for 5000", () => {
      expect(validateRedemptionAmount(5000)).toBe(true);
    });

    it("returns false for 500 (not a multiple of 1000)", () => {
      expect(validateRedemptionAmount(500)).toBe(false);
    });

    it("returns false for 1500 (not a multiple of 1000)", () => {
      expect(validateRedemptionAmount(1500)).toBe(false);
    });

    it("returns false for 0", () => {
      expect(validateRedemptionAmount(0)).toBe(false);
    });

    it("returns false for negative values", () => {
      expect(validateRedemptionAmount(-1000)).toBe(false);
    });

    it("returns false for non-integer values", () => {
      expect(validateRedemptionAmount(1000.5)).toBe(false);
    });

    it("returns false for NaN", () => {
      expect(validateRedemptionAmount(NaN)).toBe(false);
    });

    it("returns true for very large valid multiples of 1000", () => {
      expect(validateRedemptionAmount(100000)).toBe(true);
      expect(validateRedemptionAmount(1000000)).toBe(true);
    });

    it("returns false for Infinity", () => {
      expect(validateRedemptionAmount(Infinity)).toBe(false);
    });
  });

  // ── Authentication ──────────────────────────────────────────────────────────

  describe("authentication", () => {
    it("throws unauthenticated error when auth is missing", async () => {
      const request = {
        data: { redeemedCoins: 1000, orderId: "order-123" },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "unauthenticated",
      });
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });
  });

  // ── Input validation ────────────────────────────────────────────────────────

  describe("input validation", () => {
    it("throws invalid-argument when redeemedCoins is not a multiple of 1000 (Req 2 AC2)", async () => {
      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 500, orderId: "order-123" },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "invalid-argument",
      });
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("throws invalid-argument when redeemedCoins is 0", async () => {
      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 0, orderId: "order-123" },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "invalid-argument",
      });
    });

    it("throws invalid-argument when redeemedCoins is negative", async () => {
      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: -1000, orderId: "order-123" },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "invalid-argument",
      });
    });

    it("throws invalid-argument when orderId is missing", async () => {
      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000 },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "invalid-argument",
      });
    });

    it("throws invalid-argument when orderId is not a string", async () => {
      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000, orderId: 12345 },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "invalid-argument",
      });
    });
  });

  // ── Balance validation ──────────────────────────────────────────────────────

  describe("balance validation", () => {
    it("throws failed-precondition when balance < redeemedCoins (Req 2 AC1, Req 2 AC5)", async () => {
      mockTransactionGet.mockResolvedValue({
        data: () => ({ coinBalance: 500 }),
      });

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000, orderId: "order-123" },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "failed-precondition",
      });
    });

    it("throws failed-precondition when user has no coinBalance field", async () => {
      mockTransactionGet.mockResolvedValue({
        data: () => ({}),
      });

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000, orderId: "order-123" },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "failed-precondition",
      });
    });

    it("succeeds when balance equals redeemedCoins exactly", async () => {
      mockTransactionGet.mockResolvedValue({
        data: () => ({ coinBalance: 1000 }),
      });

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000, orderId: "order-123" },
      };

      const result = await handler(request);
      expect(result).toEqual({ success: true });
      expect(mockTransactionUpdate).toHaveBeenCalledWith(
        expect.anything(),
        { coinBalance: 0 }
      );
    });
  });

  // ── Successful redemption ───────────────────────────────────────────────────

  describe("successful redemption", () => {
    it("debits coins and creates CoinTransaction atomically (Req 2 AC3, Req 5 AC2)", async () => {
      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 2000, orderId: "order-abc" },
      };

      const result = await handler(request);

      expect(result).toEqual({ success: true });
      expect(mockRunTransaction).toHaveBeenCalledTimes(1);

      // Verify CoinTransaction was created with negative amount
      expect(mockTransactionSet).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          amount: -2000,
          reason: "Redemption",
          orderId: "order-abc",
          timestamp: "SERVER_TIMESTAMP",
        })
      );

      // Verify coinBalance was updated (3000 - 2000 = 1000)
      expect(mockTransactionUpdate).toHaveBeenCalledWith(
        expect.anything(),
        { coinBalance: 1000 }
      );
    });

    it("redeems full balance when redeemedCoins equals balance (balance goes to 0)", async () => {
      mockTransactionGet.mockResolvedValue({
        data: () => ({ coinBalance: 3000 }),
      });

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 3000, orderId: "order-xyz" },
      };

      const result = await handler(request);

      expect(result).toEqual({ success: true });
      expect(mockTransactionUpdate).toHaveBeenCalledWith(
        expect.anything(),
        { coinBalance: 0 }
      );
    });

    it("returns success: true on successful redemption", async () => {
      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000, orderId: "order-123" },
      };

      const result = await handler(request);
      expect(result).toEqual({ success: true });
    });

    it("redeems exactly 1000 when balance is exactly 1000 (minimum redemption threshold)", async () => {
      mockTransactionGet.mockResolvedValue({
        data: () => ({ coinBalance: 1000 }),
      });

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000, orderId: "order-min" },
      };

      const result = await handler(request);

      expect(result).toEqual({ success: true });
      expect(mockTransactionSet).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          amount: -1000,
          reason: "Redemption",
          orderId: "order-min",
        })
      );
      expect(mockTransactionUpdate).toHaveBeenCalledWith(
        expect.anything(),
        { coinBalance: 0 }
      );
    });

    it("handles maximum possible redemption with very large balance", async () => {
      mockTransactionGet.mockResolvedValue({
        data: () => ({ coinBalance: 500000 }),
      });

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 500000, orderId: "order-max" },
      };

      const result = await handler(request);

      expect(result).toEqual({ success: true });
      expect(mockTransactionUpdate).toHaveBeenCalledWith(
        expect.anything(),
        { coinBalance: 0 }
      );
    });

    it("partial redemption leaves correct remaining balance", async () => {
      mockTransactionGet.mockResolvedValue({
        data: () => ({ coinBalance: 5000 }),
      });

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 3000, orderId: "order-partial" },
      };

      const result = await handler(request);

      expect(result).toEqual({ success: true });
      expect(mockTransactionUpdate).toHaveBeenCalledWith(
        expect.anything(),
        { coinBalance: 2000 } // 5000 - 3000
      );
    });
  });

  // ── Error handling ──────────────────────────────────────────────────────────

  describe("error handling", () => {
    it("re-throws HttpsError from within the transaction", async () => {
      mockTransactionGet.mockResolvedValue({
        data: () => ({ coinBalance: 500 }),
      });

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000, orderId: "order-123" },
      };

      await expect(handler(request)).rejects.toBeInstanceOf(HttpsError);
    });

    it("wraps unexpected errors as internal HttpsError", async () => {
      mockRunTransaction.mockRejectedValue(new Error("Firestore unavailable"));

      const request = {
        auth: { uid: "user-123" },
        data: { redeemedCoins: 1000, orderId: "order-123" },
      };

      await expect(handler(request)).rejects.toMatchObject({
        code: "internal",
      });
    });
  });
});
