/**
 * Unit tests for onOrderCompletedRecommendations Firestore trigger.
 *
 * Validates:
 * - Req 5 AC1: Increment Popularity_Score of each ordered meal by 1
 * - Req 5 AC2: Updated atomically using FieldValue.increment(1)
 * - Req 3 AC1: Cache invalidation forces recompute on next request
 */

// ── Mock firebase-admin ──────────────────────────────────────────────────────
const mockUpdate = jest.fn();
const mockDelete = jest.fn();
const mockDoc = jest.fn(() => ({ update: mockUpdate, delete: mockDelete }));

const mockFirestore = jest.fn(() => ({
  doc: mockDoc,
}));

const mockIncrement = jest.fn((val: number) => `INCREMENT_${val}`);

jest.mock("firebase-admin", () => ({
  firestore: Object.assign(mockFirestore, {
    FieldValue: {
      increment: (val: number) => mockIncrement(val),
    },
  }),
  apps: [true],
  initializeApp: jest.fn(),
}));

// ── Mock firebase-functions ──────────────────────────────────────────────────
jest.mock("firebase-functions", () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

// ── Mock firebase-functions/v2/firestore ─────────────────────────────────────
jest.mock("firebase-functions/v2/firestore", () => ({
  onDocumentUpdated: (_path: string, handler: Function) => handler,
}));

// ── Import AFTER mocks ───────────────────────────────────────────────────────
import { onOrderCompletedRecommendations } from "./onOrderCompleted";

// The export is the raw handler function due to our mock of onDocumentUpdated
const handler = onOrderCompletedRecommendations as unknown as (
  event: unknown
) => Promise<void>;

// ── Test helpers ─────────────────────────────────────────────────────────────
function makeEvent(
  beforeData: Record<string, unknown> | undefined,
  afterData: Record<string, unknown> | undefined,
  orderId = "order-123"
) {
  return {
    data: beforeData && afterData
      ? {
          before: { data: () => beforeData },
          after: { data: () => afterData },
        }
      : undefined,
    params: { orderId },
  };
}

// ── Tests ────────────────────────────────────────────────────────────────────
describe("onOrderCompletedRecommendations", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockUpdate.mockResolvedValue(undefined);
    mockDelete.mockResolvedValue(undefined);
  });

  // ────────────────────────────────────────────────────────────────────────
  // Guard conditions — should NOT trigger
  // ────────────────────────────────────────────────────────────────────────

  it("returns early when event data is missing", async () => {
    const event = { data: undefined, params: { orderId: "order-1" } };

    await handler(event);

    expect(mockDoc).not.toHaveBeenCalled();
  });

  it("returns early when status did not change to delivered", async () => {
    const event = makeEvent(
      { status: "confirmed", uid: "user-1", items: [{ mealId: "m1" }] },
      { status: "preparing", uid: "user-1", items: [{ mealId: "m1" }] }
    );

    await handler(event);

    expect(mockUpdate).not.toHaveBeenCalled();
    expect(mockDelete).not.toHaveBeenCalled();
  });

  it("returns early when status was already delivered (no change)", async () => {
    const event = makeEvent(
      { status: "delivered", uid: "user-1", items: [{ mealId: "m1" }] },
      { status: "delivered", uid: "user-1", items: [{ mealId: "m1" }] }
    );

    await handler(event);

    expect(mockUpdate).not.toHaveBeenCalled();
    expect(mockDelete).not.toHaveBeenCalled();
  });

  it("returns early when newStatus is undefined", async () => {
    const event = makeEvent(
      { status: "confirmed", uid: "user-1", items: [{ mealId: "m1" }] },
      { uid: "user-1", items: [{ mealId: "m1" }] } // no status field
    );

    await handler(event);

    expect(mockUpdate).not.toHaveBeenCalled();
    expect(mockDelete).not.toHaveBeenCalled();
  });

  // ────────────────────────────────────────────────────────────────────────
  // Happy path — status changes to 'delivered'
  // ────────────────────────────────────────────────────────────────────────

  it("increments popularityScore for each meal when order is delivered", async () => {
    const event = makeEvent(
      { status: "preparing", uid: "user-1", items: [{ mealId: "m1" }, { mealId: "m2" }, { mealId: "m3" }] },
      { status: "delivered", uid: "user-1", items: [{ mealId: "m1" }, { mealId: "m2" }, { mealId: "m3" }] }
    );

    await handler(event);

    // Should call doc() for each meal + once for recommendations cache
    expect(mockDoc).toHaveBeenCalledWith("meals/m1");
    expect(mockDoc).toHaveBeenCalledWith("meals/m2");
    expect(mockDoc).toHaveBeenCalledWith("meals/m3");

    // Should call update with FieldValue.increment(1) for each meal
    expect(mockUpdate).toHaveBeenCalledTimes(3);
    expect(mockUpdate).toHaveBeenCalledWith({
      popularityScore: "INCREMENT_1",
    });

    // FieldValue.increment should be called with 1
    expect(mockIncrement).toHaveBeenCalledWith(1);
  });

  it("uses FieldValue.increment(1) for atomic updates (Req 5 AC2)", async () => {
    const event = makeEvent(
      { status: "out_for_delivery", uid: "user-1", items: [{ mealId: "meal-abc" }] },
      { status: "delivered", uid: "user-1", items: [{ mealId: "meal-abc" }] }
    );

    await handler(event);

    expect(mockIncrement).toHaveBeenCalledWith(1);
    expect(mockUpdate).toHaveBeenCalledWith({
      popularityScore: "INCREMENT_1",
    });
  });

  it("deletes /recommendations/{uid} to invalidate cache", async () => {
    const event = makeEvent(
      { status: "out_for_delivery", uid: "user-42", items: [{ mealId: "m1" }] },
      { status: "delivered", uid: "user-42", items: [{ mealId: "m1" }] }
    );

    await handler(event);

    expect(mockDoc).toHaveBeenCalledWith("recommendations/user-42");
    expect(mockDelete).toHaveBeenCalledTimes(1);
  });

  // ────────────────────────────────────────────────────────────────────────
  // Edge cases
  // ────────────────────────────────────────────────────────────────────────

  it("handles order with empty items array gracefully", async () => {
    const event = makeEvent(
      { status: "preparing", uid: "user-1", items: [] },
      { status: "delivered", uid: "user-1", items: [] }
    );

    await handler(event);

    // No meal updates, but cache should still be invalidated
    expect(mockUpdate).not.toHaveBeenCalled();
    expect(mockDoc).toHaveBeenCalledWith("recommendations/user-1");
    expect(mockDelete).toHaveBeenCalledTimes(1);
  });

  it("handles order with no items field gracefully", async () => {
    const event = makeEvent(
      { status: "preparing", uid: "user-1" },
      { status: "delivered", uid: "user-1" }
    );

    await handler(event);

    // No meal updates, but cache should still be invalidated
    expect(mockUpdate).not.toHaveBeenCalled();
    expect(mockDoc).toHaveBeenCalledWith("recommendations/user-1");
    expect(mockDelete).toHaveBeenCalledTimes(1);
  });

  it("skips items without mealId", async () => {
    const event = makeEvent(
      { status: "preparing", uid: "user-1", items: [{ mealId: "m1" }, { name: "no-id" }, { mealId: "m2" }] },
      { status: "delivered", uid: "user-1", items: [{ mealId: "m1" }, { name: "no-id" }, { mealId: "m2" }] }
    );

    await handler(event);

    // Only 2 meals should be updated (the one without mealId is skipped)
    expect(mockDoc).toHaveBeenCalledWith("meals/m1");
    expect(mockDoc).toHaveBeenCalledWith("meals/m2");
    expect(mockUpdate).toHaveBeenCalledTimes(2);
  });

  it("does not delete recommendations cache when uid is missing", async () => {
    const event = makeEvent(
      { status: "preparing", items: [{ mealId: "m1" }] },
      { status: "delivered", items: [{ mealId: "m1" }] }
    );

    await handler(event);

    // Meal should still be updated
    expect(mockDoc).toHaveBeenCalledWith("meals/m1");
    expect(mockUpdate).toHaveBeenCalledTimes(1);

    // But recommendations cache should NOT be deleted (no uid)
    expect(mockDelete).not.toHaveBeenCalled();
  });

  it("handles transition from any status to delivered (not just specific ones)", async () => {
    const event = makeEvent(
      { status: "confirmed", uid: "user-1", items: [{ mealId: "m1" }] },
      { status: "delivered", uid: "user-1", items: [{ mealId: "m1" }] }
    );

    await handler(event);

    expect(mockDoc).toHaveBeenCalledWith("meals/m1");
    expect(mockUpdate).toHaveBeenCalledTimes(1);
    expect(mockDoc).toHaveBeenCalledWith("recommendations/user-1");
    expect(mockDelete).toHaveBeenCalledTimes(1);
  });
});
