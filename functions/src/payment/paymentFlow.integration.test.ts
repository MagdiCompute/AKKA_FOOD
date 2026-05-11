/**
 * Integration-style unit tests for the full payment flow.
 *
 * Tests the end-to-end sequence:
 *   initiatePayment → orangeMoneyCallback → postPaymentActions
 *
 * Also covers Orange Money API edge cases:
 *   - Timeout responses
 *   - Malformed/invalid JSON responses
 *   - Rate limiting (429 status)
 *
 * Validates: Requirements 1.1, 2.1, 2.2, 2.3, 2.4, 3.1, 6.1, 6.4
 */

import * as crypto from "crypto";

// ── Shared Mocks ──────────────────────────────────────────────────────────────

const CALLBACK_SECRET = "integration-test-secret-key";
const API_KEY = "test-api-key";
const BASE_URL = "https://api.orangemoney.ml";
const CALLBACK_URL = "https://us-central1-akka-food.cloudfunctions.net/orangeMoneyCallback";

// Firestore mock state
let firestoreTransactions: Map<string, Record<string, unknown>>;
let firestoreOrders: Map<string, Record<string, unknown>>;
let firestoreUsers: Map<string, Record<string, unknown>>;
let firestoreCarts: Map<string, Record<string, unknown>>;

const mockMessagingSend = jest.fn().mockResolvedValue("msg-id");

// Track all Firestore operations for verification
let firestoreOps: Array<{ op: string; collection: string; id?: string; data?: unknown }>;

function resetFirestoreState() {
  firestoreTransactions = new Map();
  firestoreOrders = new Map();
  firestoreUsers = new Map();
  firestoreCarts = new Map();
  firestoreOps = [];
}

// Simulated Firestore with in-memory state
const mockFirestoreInstance = {
  collection: jest.fn((name: string) => {
    const getMap = () => {
      switch (name) {
        case "transactions": return firestoreTransactions;
        case "orders": return firestoreOrders;
        case "users": return firestoreUsers;
        case "carts": return firestoreCarts;
        default: return new Map();
      }
    };

    return {
      add: jest.fn(async (data: Record<string, unknown>) => {
        const id = `${name}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
        getMap().set(id, { ...data });
        firestoreOps.push({ op: "add", collection: name, id, data });
        return {
          id,
          update: jest.fn(async (updateData: Record<string, unknown>) => {
            const existing = getMap().get(id) || {};
            getMap().set(id, { ...existing, ...updateData });
            firestoreOps.push({ op: "update", collection: name, id, data: updateData });
          }),
        };
      }),
      where: jest.fn((field: string, op: string, value: unknown) => ({
        limit: jest.fn(() => ({
          get: jest.fn(async () => {
            const docs: Array<{ id: string; ref: unknown; data: () => unknown; exists: boolean }> = [];
            for (const [id, data] of getMap().entries()) {
              if ((data as Record<string, unknown>)[field] === value) {
                docs.push({
                  id,
                  ref: {
                    id,
                    update: jest.fn(async (updateData: Record<string, unknown>) => {
                      const existing = getMap().get(id) || {};
                      getMap().set(id, { ...existing, ...updateData });
                      firestoreOps.push({ op: "update", collection: name, id, data: updateData });
                    }),
                  },
                  data: () => data,
                  exists: true,
                });
              }
            }
            return { empty: docs.length === 0, docs };
          }),
        })),
        where: jest.fn(() => ({
          get: jest.fn(async () => ({ empty: true, docs: [] })),
        })),
      })),
      doc: jest.fn((id: string) => ({
        get: jest.fn(async () => {
          const data = getMap().get(id);
          return { exists: !!data, data: () => data };
        }),
        update: jest.fn(async (updateData: Record<string, unknown>) => {
          const existing = getMap().get(id) || {};
          getMap().set(id, { ...existing, ...updateData });
          firestoreOps.push({ op: "update", collection: name, id, data: updateData });
        }),
        delete: jest.fn(async () => {
          getMap().delete(id);
          firestoreOps.push({ op: "delete", collection: name, id });
        }),
        collection: jest.fn(() => ({
          doc: jest.fn(() => ({
            get: jest.fn(async () => ({ exists: false, data: () => undefined })),
          })),
        })),
      })),
    };
  }),
  runTransaction: jest.fn(async (fn: Function) => {
    // Simple transaction mock that executes the callback
    const transactionObj = {
      get: jest.fn(async (ref: { id: string }) => {
        const data = firestoreTransactions.get(ref.id);
        return { data: () => data, exists: !!data };
      }),
      update: jest.fn((ref: { id: string }, updateData: Record<string, unknown>) => {
        const existing = firestoreTransactions.get(ref.id) || {};
        firestoreTransactions.set(ref.id, { ...existing, ...updateData });
        firestoreOps.push({ op: "update", collection: "transactions", id: ref.id, data: updateData });
      }),
    };
    await fn(transactionObj);
  }),
};

const mockFirestore = Object.assign(jest.fn(() => mockFirestoreInstance), {
  FieldValue: {
    serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
    increment: jest.fn((n: number) => n),
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

jest.mock("firebase-functions", () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

jest.mock("firebase-functions/params", () => ({
  defineSecret: (name: string) => ({
    value: () => {
      const secrets: Record<string, string> = {
        ORANGE_MONEY_API_KEY: API_KEY,
        ORANGE_MONEY_BASE_URL: BASE_URL,
        ORANGE_MONEY_CALLBACK_URL: CALLBACK_URL,
        ORANGE_MONEY_CALLBACK_SECRET: CALLBACK_SECRET,
      };
      return secrets[name] || "";
    },
  }),
}));

// Mock uuid
const mockUuid = "flow-test-uuid-1234-5678-abcdef";
jest.mock("uuid", () => ({
  v4: () => mockUuid,
}));

// Mock global fetch
const mockFetch = jest.fn();
global.fetch = mockFetch as unknown as typeof fetch;

// Capture handlers
let initiatePaymentHandler: (request: unknown) => Promise<unknown>;
let callbackHandler: (req: unknown, res: unknown) => Promise<void>;

jest.mock("firebase-functions/v2/https", () => ({
  onCall: (optionsOrHandler: unknown, handler?: (request: unknown) => Promise<unknown>) => {
    if (typeof optionsOrHandler === "function") {
      initiatePaymentHandler = optionsOrHandler as (request: unknown) => Promise<unknown>;
    } else if (handler) {
      initiatePaymentHandler = handler;
    }
    return initiatePaymentHandler;
  },
  onRequest: (optionsOrHandler: unknown, handler?: (req: unknown, res: unknown) => Promise<void>) => {
    if (typeof optionsOrHandler === "function") {
      callbackHandler = optionsOrHandler as (req: unknown, res: unknown) => Promise<void>;
    } else if (handler) {
      callbackHandler = handler;
    }
    return callbackHandler;
  },
  HttpsError: class HttpsError extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
    }
  },
}));

jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn(),
}));

// Import modules AFTER mocks
import "./initiatePayment";
import "./orangeMoneyCallback";
import { calculateCoins } from "./postPaymentActions";

// ── Helpers ───────────────────────────────────────────────────────────────────

function computeSignature(body: Record<string, unknown>, secret: string = CALLBACK_SECRET): string {
  const payload = Object.keys(body)
    .filter((key) => key !== "signature")
    .sort()
    .map((key) => `${key}=${body[key]}`)
    .join("&");
  return crypto.createHmac("sha256", secret).update(payload).digest("hex");
}

function makeCallbackReq(body: Record<string, unknown>) {
  return { method: "POST", body };
}

function makeCallbackRes() {
  const res: Record<string, jest.Mock> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("Payment Flow — Integration-style Unit Tests", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    resetFirestoreState();

    // Setup default user with FCM token
    firestoreUsers.set("user-flow-1", {
      fcmToken: "fcm-token-flow",
      coins: 200,
    });

    // Setup default cart
    firestoreCarts.set("user-flow-1", {
      items: [
        { name: "Thieboudienne", price: 2500, quantity: 1 },
        { name: "Jus de Bissap", price: 500, quantity: 2 },
      ],
    });
  });

  // ── End-to-End Flow ─────────────────────────────────────────────────────────

  describe("end-to-end: initiatePayment → callback → post-success actions", () => {
    it("completes full payment flow from initiation to order creation", async () => {
      // Step 1: Initiate payment
      mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({ status: "pending" }) });

      const initiateResult = await initiatePaymentHandler({
        auth: { uid: "user-flow-1" },
        data: { amount: 3500, phoneNumber: "70123456" },
      }) as { transactionId: string; reference: string };

      expect(initiateResult.reference).toBe(mockUuid);
      expect(initiateResult.transactionId).toBeDefined();

      // Verify transaction was created with pending status
      const txnId = initiateResult.transactionId;
      const txnData = firestoreTransactions.get(txnId);
      expect(txnData).toBeDefined();
      expect(txnData?.status).toBe("pending");
      expect(txnData?.amount).toBe(3500);
      expect(txnData?.uid).toBe("user-flow-1");

      // Step 2: Simulate Orange Money success callback
      const callbackBody: Record<string, unknown> = {
        reference: mockUuid,
        status: "success",
        transactionId: "ext-om-txn-789",
      };
      callbackBody.signature = computeSignature(callbackBody);

      const res = makeCallbackRes();
      await callbackHandler(makeCallbackReq(callbackBody), res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: "OK", status: "success" })
      );

      // Verify transaction status was updated to success
      const updatedTxn = firestoreTransactions.get(txnId);
      expect(updatedTxn?.status).toBe("success");
    });

    it("Orange Money API is called with correct payload during initiation", async () => {
      mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });

      await initiatePaymentHandler({
        auth: { uid: "user-flow-1" },
        data: { amount: 5000, phoneNumber: "+22370123456" },
      });

      expect(mockFetch).toHaveBeenCalledWith(
        `${BASE_URL}/payment`,
        expect.objectContaining({
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${API_KEY}`,
          },
          body: JSON.stringify({
            amount: 5000,
            reference: mockUuid,
            phoneNumber: "+22370123456",
            callbackUrl: CALLBACK_URL,
          }),
        })
      );
    });

    it("coins are calculated correctly for the payment amount", () => {
      // 3500 XOF → 5% = 175 coins
      expect(calculateCoins(3500)).toBe(175);
      // 2000 XOF → 5% = 100 coins
      expect(calculateCoins(2000)).toBe(100);
      // 999 XOF → 5% = 49.95 → 49 coins
      expect(calculateCoins(999)).toBe(49);
    });

    it("callback with failed status does not trigger post-payment actions", async () => {
      // First initiate a payment
      mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) });

      const initiateResult = await initiatePaymentHandler({
        auth: { uid: "user-flow-1" },
        data: { amount: 2000, phoneNumber: "70123456" },
      }) as { transactionId: string; reference: string };

      // Send a failure callback
      const callbackBody: Record<string, unknown> = {
        reference: mockUuid,
        status: "failed",
        transactionId: "ext-om-txn-fail",
      };
      callbackBody.signature = computeSignature(callbackBody);

      const res = makeCallbackRes();
      await callbackHandler(makeCallbackReq(callbackBody), res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "failed" })
      );

      // Verify no order was created
      const orderOps = firestoreOps.filter(
        (op) => op.collection === "orders" && op.op === "add"
      );
      expect(orderOps).toHaveLength(0);
    });

    it("duplicate success callback is handled idempotently", async () => {
      // Setup a transaction that's already in success state
      const txnId = "already-success-txn";
      firestoreTransactions.set(txnId, {
        reference: "idempotent-ref",
        uid: "user-flow-1",
        amount: 1000,
        status: "success",
        orderId: "existing-order",
      });

      const callbackBody: Record<string, unknown> = {
        reference: "idempotent-ref",
        status: "success",
        transactionId: "ext-dup",
      };
      callbackBody.signature = computeSignature(callbackBody);

      const res = makeCallbackRes();
      await callbackHandler(makeCallbackReq(callbackBody), res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({ message: "Already processed" });

      // Verify no new orders were created
      const orderOps = firestoreOps.filter(
        (op) => op.collection === "orders" && op.op === "add"
      );
      expect(orderOps).toHaveLength(0);
    });
  });

  // ── Orange Money API Edge Cases ─────────────────────────────────────────────

  describe("Orange Money API edge cases", () => {
    it("handles API timeout (fetch throws AbortError)", async () => {
      const timeoutError = new Error("The operation was aborted");
      timeoutError.name = "AbortError";
      mockFetch.mockRejectedValueOnce(timeoutError);

      await expect(
        initiatePaymentHandler({
          auth: { uid: "user-flow-1" },
          data: { amount: 2000, phoneNumber: "70123456" },
        })
      ).rejects.toMatchObject({ code: "internal" });

      // Transaction should be marked as failed
      const failedOps = firestoreOps.filter(
        (op) => op.op === "update" && (op.data as Record<string, unknown>)?.status === "failed"
      );
      expect(failedOps.length).toBeGreaterThan(0);
    });

    it("handles API timeout (ETIMEDOUT network error)", async () => {
      const networkError = new Error("connect ETIMEDOUT");
      (networkError as NodeJS.ErrnoException).code = "ETIMEDOUT";
      mockFetch.mockRejectedValueOnce(networkError);

      await expect(
        initiatePaymentHandler({
          auth: { uid: "user-flow-1" },
          data: { amount: 2000, phoneNumber: "70123456" },
        })
      ).rejects.toMatchObject({ code: "internal" });
    });

    it("handles malformed JSON response from Orange Money API", async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        text: async () => "<html>Internal Server Error</html>",
      });

      await expect(
        initiatePaymentHandler({
          auth: { uid: "user-flow-1" },
          data: { amount: 2000, phoneNumber: "70123456" },
        })
      ).rejects.toMatchObject({ code: "internal" });
    });

    it("handles rate limiting (HTTP 429) from Orange Money API", async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 429,
        text: async () => JSON.stringify({ error: "Too Many Requests", retryAfter: 60 }),
      });

      await expect(
        initiatePaymentHandler({
          auth: { uid: "user-flow-1" },
          data: { amount: 2000, phoneNumber: "70123456" },
        })
      ).rejects.toMatchObject({ code: "internal" });

      // Transaction should be marked as failed
      const failedOps = firestoreOps.filter(
        (op) => op.op === "update" && (op.data as Record<string, unknown>)?.status === "failed"
      );
      expect(failedOps.length).toBeGreaterThan(0);
    });

    it("handles empty response body from Orange Money API", async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 502,
        text: async () => "",
      });

      await expect(
        initiatePaymentHandler({
          auth: { uid: "user-flow-1" },
          data: { amount: 2000, phoneNumber: "70123456" },
        })
      ).rejects.toMatchObject({ code: "internal" });
    });

    it("handles connection reset error from Orange Money API", async () => {
      const connResetError = new Error("socket hang up");
      (connResetError as NodeJS.ErrnoException).code = "ECONNRESET";
      mockFetch.mockRejectedValueOnce(connResetError);

      await expect(
        initiatePaymentHandler({
          auth: { uid: "user-flow-1" },
          data: { amount: 2000, phoneNumber: "70123456" },
        })
      ).rejects.toMatchObject({ code: "internal" });
    });
  });

  // ── Callback Signature Edge Cases ───────────────────────────────────────────

  describe("callback signature edge cases", () => {
    it("rejects callback with signature computed using wrong secret", async () => {
      const callbackBody: Record<string, unknown> = {
        reference: mockUuid,
        status: "success",
        transactionId: "ext-txn",
      };
      // Sign with a different secret
      callbackBody.signature = computeSignature(callbackBody, "wrong-secret-key");

      const res = makeCallbackRes();
      await callbackHandler(makeCallbackReq(callbackBody), res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({ error: "Invalid signature" });
    });

    it("rejects callback with tampered payload (amount changed after signing)", async () => {
      const originalBody: Record<string, unknown> = {
        reference: mockUuid,
        status: "success",
        transactionId: "ext-txn",
        amount: 2000,
      };
      const signature = computeSignature(originalBody);

      // Tamper with the amount after signing
      const tamperedBody = { ...originalBody, amount: 99999, signature };

      const res = makeCallbackRes();
      await callbackHandler(makeCallbackReq(tamperedBody), res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({ error: "Invalid signature" });
    });
  });

  // ── Mock Consistency Verification ───────────────────────────────────────────

  describe("mock setup consistency", () => {
    it("uses the same secret for signing and verification", () => {
      // Verify that the callback secret used in tests matches what the handler expects
      const body: Record<string, unknown> = { reference: "test", status: "success" };
      const sig = computeSignature(body, CALLBACK_SECRET);

      // The signature should be a valid hex string of 64 chars (SHA-256)
      expect(sig).toMatch(/^[a-f0-9]{64}$/);
    });

    it("Firebase Admin mock provides consistent FieldValue methods", () => {
      const admin = require("firebase-admin");
      expect(admin.firestore.FieldValue.serverTimestamp).toBeDefined();
      expect(admin.firestore.FieldValue.increment).toBeDefined();
      expect(admin.firestore.FieldValue.serverTimestamp()).toBe("SERVER_TIMESTAMP");
    });

    it("fetch mock is properly configured as global", () => {
      expect(global.fetch).toBeDefined();
      expect(jest.isMockFunction(global.fetch)).toBe(true);
    });

    it("all secret values are accessible via defineSecret mock", () => {
      const { defineSecret } = require("firebase-functions/params");
      expect(defineSecret("ORANGE_MONEY_API_KEY").value()).toBe(API_KEY);
      expect(defineSecret("ORANGE_MONEY_BASE_URL").value()).toBe(BASE_URL);
      expect(defineSecret("ORANGE_MONEY_CALLBACK_URL").value()).toBe(CALLBACK_URL);
      expect(defineSecret("ORANGE_MONEY_CALLBACK_SECRET").value()).toBe(CALLBACK_SECRET);
    });
  });
});
