/**
 * Unit tests for orangeMoneyCallback Cloud Function.
 *
 * Validates:
 * - Req 6 AC1: Validate callback signatures before processing
 * - Req 6 AC4: Idempotent — same callback twice won't duplicate effects
 * - Req 6 AC3: Log all Transaction state changes with timestamps
 * - Req 2 AC1: Update Transaction status to `success` on success callback
 * - Req 3 AC1: Update Transaction status to `failed` on failure callback
 */

import * as crypto from "crypto";

// ── Mocks ─────────────────────────────────────────────────────────────────────

const mockUpdate = jest.fn();
const mockRunTransaction = jest.fn();
const mockWhere = jest.fn();
const mockLimit = jest.fn();
const mockQueryGet = jest.fn();

const mockCollection = jest.fn(() => ({
  where: mockWhere,
}));

mockWhere.mockReturnValue({ limit: mockLimit });
mockLimit.mockReturnValue({ get: mockQueryGet });

const mockFirestore = Object.assign(jest.fn(() => ({
  collection: mockCollection,
  runTransaction: mockRunTransaction,
})), {
  FieldValue: { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") },
});

jest.mock("firebase-admin", () => ({
  firestore: mockFirestore,
  apps: [true],
  initializeApp: jest.fn(),
}));

// Mock firebase-functions logger
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

// Mock defineSecret
const CALLBACK_SECRET = "test-callback-secret-key-12345";

jest.mock("firebase-functions/params", () => ({
  defineSecret: (name: string) => ({
    value: () => {
      if (name === "ORANGE_MONEY_CALLBACK_SECRET") return CALLBACK_SECRET;
      return "";
    },
  }),
}));

// Mock onRequest to capture the handler
let capturedHandler: (req: unknown, res: unknown) => Promise<void>;

jest.mock("firebase-functions/v2/https", () => ({
  onRequest: (optionsOrHandler: unknown, handler?: (req: unknown, res: unknown) => Promise<void>) => {
    if (typeof optionsOrHandler === "function") {
      capturedHandler = optionsOrHandler as (req: unknown, res: unknown) => Promise<void>;
    } else if (handler) {
      capturedHandler = handler;
    }
    return capturedHandler;
  },
}));

// Import AFTER mocks
import { computeHmacSignature } from "./orangeMoneyCallback";
import "./orangeMoneyCallback";

// ── Helpers ───────────────────────────────────────────────────────────────────

function createSignature(body: Record<string, unknown>, secret: string = CALLBACK_SECRET): string {
  const payload = Object.keys(body)
    .filter((key) => key !== "signature")
    .sort()
    .map((key) => `${key}=${body[key]}`)
    .join("&");

  return crypto.createHmac("sha256", secret).update(payload).digest("hex");
}

function makeCallbackBody(overrides: Partial<{
  reference: string;
  status: string;
  transactionId: string;
  signature: string;
}> = {}) {
  const base: Record<string, unknown> = {
    reference: "ref-123-abc",
    status: "success",
    transactionId: "ext-txn-456",
    ...overrides,
  };

  // Compute signature if not explicitly provided
  if (!overrides.signature) {
    base.signature = createSignature(base);
  } else {
    base.signature = overrides.signature;
  }

  return base;
}

function makeReq(body: Record<string, unknown>, method = "POST") {
  return { method, body };
}

function makeRes() {
  const res: Record<string, jest.Mock> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res;
}

function makeTransactionDoc(data: Record<string, unknown>, id = "doc-id-1") {
  return {
    id,
    ref: { id, update: mockUpdate },
    data: () => data,
    exists: true,
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("orangeMoneyCallback", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockWhere.mockReturnValue({ limit: mockLimit });
    mockLimit.mockReturnValue({ get: mockQueryGet });
  });

  // ── Method validation ───────────────────────────────────────────────────────

  describe("HTTP method validation", () => {
    it("rejects non-POST requests with 405", async () => {
      const body = makeCallbackBody();
      const req = makeReq(body, "GET");
      const res = makeRes();

      await capturedHandler(req, res);

      expect(res.status).toHaveBeenCalledWith(405);
      expect(res.json).toHaveBeenCalledWith({ error: "Method not allowed" });
    });
  });

  // ── Signature validation (Req 6 AC1) ───────────────────────────────────────

  describe("HMAC signature validation", () => {
    it("rejects requests with missing signature", async () => {
      const req = makeReq({
        reference: "ref-123",
        status: "success",
        transactionId: "ext-txn-456",
        // no signature field
      });
      const res = makeRes();

      await capturedHandler(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: "Missing required fields" });
    });

    it("rejects requests with missing reference", async () => {
      const req = makeReq({
        status: "success",
        transactionId: "ext-txn-456",
        signature: "some-sig",
      });
      const res = makeRes();

      await capturedHandler(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: "Missing required fields" });
    });

    it("rejects requests with missing status", async () => {
      const req = makeReq({
        reference: "ref-123",
        transactionId: "ext-txn-456",
        signature: "some-sig",
      });
      const res = makeRes();

      await capturedHandler(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: "Missing required fields" });
    });

    it("rejects requests with invalid HMAC signature", async () => {
      const body = makeCallbackBody({ signature: "a".repeat(64) });
      const req = makeReq(body);
      const res = makeRes();

      await capturedHandler(req, res);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({ error: "Invalid signature" });
    });

    it("accepts requests with valid HMAC signature", async () => {
      const body = makeCallbackBody();
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "pending", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(res.status).toHaveBeenCalledWith(200);
    });
  });

  // ── Transaction lookup ──────────────────────────────────────────────────────

  describe("transaction lookup", () => {
    it("returns 404 when transaction reference is not found", async () => {
      const body = makeCallbackBody();
      const req = makeReq(body);
      const res = makeRes();

      mockQueryGet.mockResolvedValue({ empty: true, docs: [] });

      await capturedHandler(req, res);

      expect(mockWhere).toHaveBeenCalledWith("reference", "==", "ref-123-abc");
      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({ error: "Transaction not found" });
    });

    it("queries Firestore by reference field", async () => {
      const body = makeCallbackBody({ reference: "my-unique-ref" });
      const req = makeReq(body);
      const res = makeRes();

      mockQueryGet.mockResolvedValue({ empty: true, docs: [] });

      await capturedHandler(req, res);

      expect(mockCollection).toHaveBeenCalledWith("transactions");
      expect(mockWhere).toHaveBeenCalledWith("reference", "==", "my-unique-ref");
      expect(mockLimit).toHaveBeenCalledWith(1);
    });
  });

  // ── Unknown status handling ─────────────────────────────────────────────────

  describe("unknown callback status", () => {
    it("returns 400 for unrecognized status values", async () => {
      const body = makeCallbackBody({ status: "unknown_status" });
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "pending", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });

      await capturedHandler(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: "Unknown status" });
    });
  });

  // ── Idempotency (Req 6 AC4) ────────────────────────────────────────────────

  describe("idempotency", () => {
    it("returns 200 immediately if transaction is already success", async () => {
      const body = makeCallbackBody();
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "success", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({ message: "Already processed" });
      // Should NOT call update since it's already processed
      expect(mockUpdate).not.toHaveBeenCalled();
    });

    it("logs duplicate callback detection", async () => {
      const body = makeCallbackBody();
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "success", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(mockLoggerInfo).toHaveBeenCalledWith(
        "Duplicate callback — already processed",
        expect.objectContaining({
          transactionId: "doc-id-1",
          reference: "ref-123-abc",
          currentStatus: "success",
        })
      );
    });
  });

  // ── Status update — success (Req 2 AC1) ────────────────────────────────────

  describe("success status update", () => {
    it("updates transaction status to success", async () => {
      const body = makeCallbackBody({ status: "success" });
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "pending", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(mockUpdate).toHaveBeenCalledWith(
        txnDoc.ref,
        expect.objectContaining({ status: "success", updatedAt: "SERVER_TIMESTAMP" })
      );
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({ message: "OK", status: "success" });
    });

    it("maps 'successful' callback status to internal success", async () => {
      const body = makeCallbackBody({ status: "successful" });
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "pending", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(mockUpdate).toHaveBeenCalledWith(
        txnDoc.ref,
        expect.objectContaining({ status: "success" })
      );
    });
  });

  // ── Status update — failed (Req 3 AC1) ─────────────────────────────────────

  describe("failure status update", () => {
    it("updates transaction status to failed", async () => {
      const body = makeCallbackBody({ status: "failed" });
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "pending", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(mockUpdate).toHaveBeenCalledWith(
        txnDoc.ref,
        expect.objectContaining({ status: "failed", updatedAt: "SERVER_TIMESTAMP" })
      );
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({ message: "OK", status: "failed" });
    });

    it("maps 'rejected' callback status to internal failed", async () => {
      const body = makeCallbackBody({ status: "rejected" });
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "pending", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(mockUpdate).toHaveBeenCalledWith(
        txnDoc.ref,
        expect.objectContaining({ status: "failed" })
      );
    });
  });

  // ── Cancelled status ────────────────────────────────────────────────────────

  describe("cancelled status update", () => {
    it("updates transaction status to cancelled", async () => {
      const body = makeCallbackBody({ status: "cancelled" });
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "pending", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(mockUpdate).toHaveBeenCalledWith(
        txnDoc.ref,
        expect.objectContaining({ status: "cancelled" })
      );
      expect(res.status).toHaveBeenCalledWith(200);
    });
  });

  // ── Audit logging (Req 6 AC3) ──────────────────────────────────────────────

  describe("audit logging", () => {
    it("logs transaction state change on successful update", async () => {
      const body = makeCallbackBody({ status: "success" });
      const req = makeReq(body);
      const res = makeRes();

      const txnDoc = makeTransactionDoc({ status: "pending", reference: "ref-123-abc" });
      mockQueryGet.mockResolvedValue({ empty: false, docs: [txnDoc] });
      mockRunTransaction.mockImplementation(async (fn: Function) => {
        await fn({
          get: jest.fn().mockResolvedValue(txnDoc),
          update: mockUpdate,
        });
      });

      await capturedHandler(req, res);

      expect(mockLoggerInfo).toHaveBeenCalledWith(
        "Transaction status updated",
        expect.objectContaining({
          transactionId: "doc-id-1",
          reference: "ref-123-abc",
          oldStatus: "pending",
          newStatus: "success",
        })
      );
    });

    it("logs warning for invalid signature attempts", async () => {
      const body = makeCallbackBody({ signature: "b".repeat(64) });
      const req = makeReq(body);
      const res = makeRes();

      await capturedHandler(req, res);

      expect(mockLoggerWarn).toHaveBeenCalledWith(
        "Invalid callback signature",
        expect.objectContaining({ reference: "ref-123-abc" })
      );
    });
  });

  // ── computeHmacSignature utility ───────────────────────────────────────────

  describe("computeHmacSignature", () => {
    it("excludes the signature field from computation", () => {
      const body = { reference: "ref-1", status: "success", signature: "should-be-excluded" };
      const sig = computeHmacSignature(body, "secret");

      // Compute expected manually
      const payload = "reference=ref-1&status=success";
      const expected = crypto.createHmac("sha256", "secret").update(payload).digest("hex");

      expect(sig).toBe(expected);
    });

    it("sorts keys alphabetically", () => {
      const body1 = { z: "last", a: "first", m: "middle" };
      const body2 = { a: "first", m: "middle", z: "last" };

      expect(computeHmacSignature(body1, "key")).toBe(computeHmacSignature(body2, "key"));
    });

    it("produces different signatures for different secrets", () => {
      const body = { reference: "ref-1", status: "success" };

      const sig1 = computeHmacSignature(body, "secret1");
      const sig2 = computeHmacSignature(body, "secret2");

      expect(sig1).not.toBe(sig2);
    });

    it("produces different signatures for different payloads", () => {
      const body1 = { reference: "ref-1", status: "success" };
      const body2 = { reference: "ref-2", status: "success" };

      const sig1 = computeHmacSignature(body1, "secret");
      const sig2 = computeHmacSignature(body2, "secret");

      expect(sig1).not.toBe(sig2);
    });
  });
});
