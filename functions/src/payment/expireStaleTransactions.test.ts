/**
 * Unit tests for expireStaleTransactions Cloud Function.
 *
 * Validates: Requirements 3.1, 6.3
 *
 * Covers:
 *  - Queries Firestore for pending transactions older than 5 minutes
 *  - Updates stale transactions to `failed` status with updatedAt timestamp
 *  - Uses batch writes for efficiency
 *  - Logs each expiration for audit purposes
 *  - Handles empty result set gracefully
 */

// ── Mocks ─────────────────────────────────────────────────────────────────────

const mockBatchUpdate = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  update: mockBatchUpdate,
  commit: mockBatchCommit,
}));

const mockWhere = jest.fn().mockReturnThis();
const mockGet = jest.fn();
const mockCollection = jest.fn(() => ({
  where: mockWhere,
  get: mockGet,
}));

const mockFirestore = Object.assign(jest.fn(() => ({
  collection: mockCollection,
  batch: mockBatch,
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
jest.mock("firebase-functions", () => ({
  logger: {
    info: mockLoggerInfo,
    error: jest.fn(),
  },
}));

// Mock onSchedule to capture the handler
let capturedHandler: () => Promise<void>;
jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: (schedule: string, handler: () => Promise<void>) => {
    capturedHandler = handler;
    return handler;
  },
}));

// Import AFTER mocks
import "../payment/expireStaleTransactions";

// ── Helpers ───────────────────────────────────────────────────────────────────

function makeDoc(id: string, data: Record<string, unknown>) {
  return {
    id,
    ref: { path: `transactions/${id}` },
    data: () => data,
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("expireStaleTransactions", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("does nothing when no stale transactions are found", async () => {
    mockGet.mockResolvedValueOnce({ empty: true, docs: [] });

    await capturedHandler();

    expect(mockBatch).not.toHaveBeenCalled();
    expect(mockLoggerInfo).toHaveBeenCalledWith(
      "No stale transactions found",
      expect.objectContaining({ timestamp: expect.any(String) })
    );
  });

  it("queries Firestore for pending transactions older than 5 minutes", async () => {
    mockGet.mockResolvedValueOnce({ empty: true, docs: [] });

    await capturedHandler();

    expect(mockCollection).toHaveBeenCalledWith("transactions");
    expect(mockWhere).toHaveBeenCalledWith("status", "==", "pending");
    expect(mockWhere).toHaveBeenCalledWith("createdAt", "<", expect.any(Date));

    // Verify the date is approximately 5 minutes ago
    const dateArg = mockWhere.mock.calls.find(
      (call: unknown[]) => call[0] === "createdAt"
    )?.[2] as Date;
    const fiveMinutesAgo = Date.now() - 5 * 60 * 1000;
    expect(dateArg.getTime()).toBeCloseTo(fiveMinutesAgo, -3); // within 1 second
  });

  it("updates stale transactions to failed status using batch writes", async () => {
    const staleDocs = [
      makeDoc("txn-1", { reference: "ref-1", uid: "user-1", status: "pending" }),
      makeDoc("txn-2", { reference: "ref-2", uid: "user-2", status: "pending" }),
    ];

    mockGet.mockResolvedValueOnce({ empty: false, docs: staleDocs });

    await capturedHandler();

    expect(mockBatch).toHaveBeenCalledTimes(1);
    expect(mockBatchUpdate).toHaveBeenCalledTimes(2);
    expect(mockBatchUpdate).toHaveBeenCalledWith(
      staleDocs[0].ref,
      { status: "failed", updatedAt: "SERVER_TIMESTAMP" }
    );
    expect(mockBatchUpdate).toHaveBeenCalledWith(
      staleDocs[1].ref,
      { status: "failed", updatedAt: "SERVER_TIMESTAMP" }
    );
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
  });

  it("logs each expired transaction for audit purposes", async () => {
    const staleDocs = [
      makeDoc("txn-1", { reference: "ref-1", uid: "user-1", status: "pending" }),
    ];

    mockGet.mockResolvedValueOnce({ empty: false, docs: staleDocs });

    await capturedHandler();

    expect(mockLoggerInfo).toHaveBeenCalledWith(
      "Transaction expired",
      expect.objectContaining({
        transactionId: "txn-1",
        reference: "ref-1",
        uid: "user-1",
        oldStatus: "pending",
        newStatus: "failed",
        reason: "Payment timeout — pending for more than 5 minutes",
        timestamp: expect.any(String),
      })
    );
  });

  it("logs the total count of expired transactions", async () => {
    const staleDocs = [
      makeDoc("txn-1", { reference: "ref-1", uid: "user-1", status: "pending" }),
      makeDoc("txn-2", { reference: "ref-2", uid: "user-2", status: "pending" }),
      makeDoc("txn-3", { reference: "ref-3", uid: "user-3", status: "pending" }),
    ];

    mockGet.mockResolvedValueOnce({ empty: false, docs: staleDocs });

    await capturedHandler();

    expect(mockLoggerInfo).toHaveBeenCalledWith(
      "Stale transactions expired",
      expect.objectContaining({ count: 3, timestamp: expect.any(String) })
    );
  });

  it("handles multiple batches when there are more than 500 transactions", async () => {
    // Create 501 mock documents to trigger two batches
    const staleDocs = Array.from({ length: 501 }, (_, i) =>
      makeDoc(`txn-${i}`, { reference: `ref-${i}`, uid: `user-${i}`, status: "pending" })
    );

    mockGet.mockResolvedValueOnce({ empty: false, docs: staleDocs });

    await capturedHandler();

    // Should create 2 batches: one with 500 docs, one with 1 doc
    expect(mockBatch).toHaveBeenCalledTimes(2);
    expect(mockBatchCommit).toHaveBeenCalledTimes(2);
    expect(mockBatchUpdate).toHaveBeenCalledTimes(501);
  });
});
