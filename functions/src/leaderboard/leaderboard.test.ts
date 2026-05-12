/**
 * Unit tests for Leaderboard Cloud Functions.
 *
 * Tests cover:
 * - rebuildLeaderboard helper functions (getMonthlyDocId, getWeeklyDocId, getIsoWeekNumber)
 * - onOrderCompletedLeaderboard trigger logic (status filtering, idempotency, missing uid)
 * - resetWeeklyScores / resetMonthlyScores helper functions (getPreviousWeekDocId, getPreviousMonthDocId)
 */

// ── Pure helper imports (no mocks needed) ─────────────────────────────────────

import {
  getMonthlyDocId,
  getWeeklyDocId,
  getIsoWeekNumber,
} from "./rebuildLeaderboard";
import { getPreviousMonthDocId } from "./resetMonthlyScores";
import { getPreviousWeekDocId, getIsoWeekYear } from "./resetWeeklyScores";

// ── Tests for rebuildLeaderboard helpers ──────────────────────────────────────

describe("rebuildLeaderboard helpers", () => {
  describe("getMonthlyDocId", () => {
    it("returns correct format for January 2024", () => {
      const date = new Date(2024, 0, 15); // Jan 15, 2024
      expect(getMonthlyDocId(date)).toBe("monthly_2024_01");
    });

    it("returns correct format for December 2023", () => {
      const date = new Date(2023, 11, 25); // Dec 25, 2023
      expect(getMonthlyDocId(date)).toBe("monthly_2023_12");
    });

    it("returns correct format for June 2025", () => {
      const date = new Date(2025, 5, 1); // Jun 1, 2025
      expect(getMonthlyDocId(date)).toBe("monthly_2025_06");
    });

    it("zero-pads single-digit months", () => {
      const date = new Date(2024, 2, 10); // Mar 10, 2024
      expect(getMonthlyDocId(date)).toBe("monthly_2024_03");
    });

    it("handles last day of month correctly", () => {
      const date = new Date(2024, 1, 29); // Feb 29, 2024 (leap year)
      expect(getMonthlyDocId(date)).toBe("monthly_2024_02");
    });
  });

  describe("getWeeklyDocId", () => {
    it("returns correct format for a mid-year date", () => {
      // June 12, 2024 is a Wednesday in ISO week 24
      const date = new Date(2024, 5, 12);
      const result = getWeeklyDocId(date);
      expect(result).toMatch(/^weekly_2024_\d{2}$/);
      expect(result).toBe("weekly_2024_24");
    });

    it("returns correct format for first week of year", () => {
      // Jan 4, 2024 is always in ISO week 1
      const date = new Date(2024, 0, 4);
      expect(getWeeklyDocId(date)).toBe("weekly_2024_01");
    });

    it("zero-pads single-digit week numbers", () => {
      // Jan 8, 2024 is a Monday in ISO week 2
      const date = new Date(2024, 0, 8);
      expect(getWeeklyDocId(date)).toBe("weekly_2024_02");
    });

    it("handles last week of year", () => {
      // Dec 28, 2023 is in the last week of 2023
      const date = new Date(2023, 11, 28);
      const result = getWeeklyDocId(date);
      expect(result).toMatch(/^weekly_2023_52$/);
    });
  });

  describe("getIsoWeekNumber", () => {
    it("returns 1 for January 4 (always in week 1)", () => {
      // Jan 4 is always in ISO week 1 by definition
      expect(getIsoWeekNumber(new Date(2024, 0, 4))).toBe(1);
      expect(getIsoWeekNumber(new Date(2023, 0, 4))).toBe(1);
    });

    it("returns 1 for January 1, 2024 (Monday, start of week 1)", () => {
      // Jan 1, 2024 is a Monday → ISO week 1
      expect(getIsoWeekNumber(new Date(2024, 0, 1))).toBe(1);
    });

    it("handles year boundary: Dec 31, 2024 can be week 1 of next year", () => {
      // Dec 31, 2024 is a Tuesday. The Thursday of that week is Jan 2, 2025
      // so it belongs to ISO week 1 of 2025
      const result = getIsoWeekNumber(new Date(2024, 11, 31));
      expect(result).toBe(1);
    });

    it("handles year boundary: Jan 1, 2023 is in week 52 of 2022", () => {
      // Jan 1, 2023 is a Sunday. The Thursday of that ISO week is Dec 29, 2022
      // so it belongs to ISO week 52 of 2022
      const result = getIsoWeekNumber(new Date(2023, 0, 1));
      expect(result).toBe(52);
    });

    it("returns correct week for a mid-year date", () => {
      // June 15, 2024 is a Saturday in ISO week 24
      expect(getIsoWeekNumber(new Date(2024, 5, 15))).toBe(24);
    });

    it("handles week 53 in years that have it", () => {
      // 2020 has 53 ISO weeks. Dec 31, 2020 is a Thursday → week 53
      expect(getIsoWeekNumber(new Date(2020, 11, 31))).toBe(53);
    });

    it("does not mutate the input date", () => {
      const date = new Date(2024, 5, 15);
      const originalTime = date.getTime();
      getIsoWeekNumber(date);
      expect(date.getTime()).toBe(originalTime);
    });
  });
});

// ── Tests for resetMonthlyScores helper ───────────────────────────────────────

describe("resetMonthlyScores helpers", () => {
  describe("getPreviousMonthDocId", () => {
    it("returns previous month for a mid-year date", () => {
      // June 1, 2024 → previous month is May 2024
      const date = new Date(Date.UTC(2024, 5, 1));
      expect(getPreviousMonthDocId(date)).toBe("monthly_2024_05");
    });

    it("handles year boundary: January → December of previous year", () => {
      // Jan 1, 2024 → previous month is December 2023
      const date = new Date(Date.UTC(2024, 0, 1));
      expect(getPreviousMonthDocId(date)).toBe("monthly_2023_12");
    });

    it("handles February correctly", () => {
      // Feb 1, 2024 → previous month is January 2024
      const date = new Date(Date.UTC(2024, 1, 1));
      expect(getPreviousMonthDocId(date)).toBe("monthly_2024_01");
    });

    it("zero-pads single-digit months", () => {
      // April 1, 2024 → previous month is March 2024
      const date = new Date(Date.UTC(2024, 3, 1));
      expect(getPreviousMonthDocId(date)).toBe("monthly_2024_03");
    });

    it("handles December → November correctly", () => {
      // Dec 1, 2024 → previous month is November 2024
      const date = new Date(Date.UTC(2024, 11, 1));
      expect(getPreviousMonthDocId(date)).toBe("monthly_2024_11");
    });
  });
});

// ── Tests for resetWeeklyScores helpers ───────────────────────────────────────

describe("resetWeeklyScores helpers", () => {
  describe("getPreviousWeekDocId", () => {
    it("returns previous week doc ID for a mid-year Monday", () => {
      // June 17, 2024 is a Monday (week 25). Previous week is week 24
      const date = new Date(2024, 5, 17);
      expect(getPreviousWeekDocId(date)).toBe("weekly_2024_24");
    });

    it("handles year boundary: first Monday of January", () => {
      // Jan 8, 2024 is a Monday (week 2). Previous week is week 1
      const date = new Date(2024, 0, 8);
      expect(getPreviousWeekDocId(date)).toBe("weekly_2024_01");
    });

    it("handles crossing into previous year", () => {
      // Jan 1, 2024 is a Monday (week 1). 7 days before is Dec 25, 2023
      // Dec 25, 2023 is in ISO week 52 of 2023
      const date = new Date(2024, 0, 1);
      expect(getPreviousWeekDocId(date)).toBe("weekly_2023_52");
    });

    it("zero-pads single-digit week numbers", () => {
      // Jan 15, 2024 is a Monday (week 3). Previous week is week 2
      const date = new Date(2024, 0, 15);
      expect(getPreviousWeekDocId(date)).toBe("weekly_2024_02");
    });
  });

  describe("getIsoWeekYear", () => {
    it("returns the calendar year for a mid-year date", () => {
      expect(getIsoWeekYear(new Date(2024, 5, 15))).toBe(2024);
    });

    it("returns next year for Dec 31 when it falls in week 1 of next year", () => {
      // Dec 31, 2024 is a Tuesday → Thursday of that week is Jan 2, 2025
      // ISO week year is 2025
      expect(getIsoWeekYear(new Date(2024, 11, 31))).toBe(2025);
    });

    it("returns previous year for Jan 1 when it falls in last week of previous year", () => {
      // Jan 1, 2023 is a Sunday → Thursday of that ISO week is Dec 29, 2022
      // ISO week year is 2022
      expect(getIsoWeekYear(new Date(2023, 0, 1))).toBe(2022);
    });
  });
});

// ── Tests for onOrderCompletedLeaderboard trigger logic ───────────────────────

describe("onOrderCompletedLeaderboard", () => {
  // Mock firebase-admin, firebase-functions, and PubSub
  const mockTransactionGet = jest.fn();
  const mockTransactionSet = jest.fn();
  const mockRunTransaction = jest.fn();
  const mockDelete = jest.fn();
  const mockPublishMessage = jest.fn();

  const mockDocRef = { id: "user-123" };
  const mockDb = {
    doc: jest.fn().mockReturnValue(mockDocRef),
    runTransaction: mockRunTransaction,
  };

  beforeAll(() => {
    // Set up mocks before importing the module
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

    jest.mock("@google-cloud/pubsub", () => ({
      PubSub: jest.fn().mockImplementation(() => ({
        topic: jest.fn().mockReturnValue({
          publishMessage: mockPublishMessage.mockResolvedValue("msg-id"),
        }),
      })),
    }));
  });

  let handler: (event: unknown) => Promise<void>;

  beforeAll(async () => {
    const mod = await import("./onOrderCompleted");
    handler = mod.onOrderCompletedLeaderboard as unknown as (event: unknown) => Promise<void>;
  });

  beforeEach(() => {
    jest.clearAllMocks();

    mockRunTransaction.mockImplementation(
      async (cb: (t: { get: jest.Mock; set: jest.Mock }) => Promise<void>) => {
        await cb({
          get: mockTransactionGet,
          set: mockTransactionSet,
        });
      }
    );

    mockTransactionGet.mockResolvedValue({
      data: () => ({ allTimeScore: 5, monthlyScore: 2, weeklyScore: 1 }),
    });

    mockDelete.mockResolvedValue(undefined);
    (mockDocRef as any).delete = mockDelete;
  });

  function makeEvent(
    beforeStatus: string | undefined,
    afterStatus: string | undefined,
    afterData: Record<string, unknown> = {}
  ) {
    return {
      data: {
        before: { data: () => ({ status: beforeStatus }) },
        after: {
          data: () => ({
            status: afterStatus,
            uid: "user-123",
            ...afterData,
          }),
        },
      },
      params: { orderId: "order-001" },
    };
  }

  describe("status filtering", () => {
    it("triggers score increment for 'delivered' status", async () => {
      const event = makeEvent("pending", "delivered");
      await handler(event);
      expect(mockRunTransaction).toHaveBeenCalledTimes(1);
    });

    it("triggers score increment for 'completed' status", async () => {
      const event = makeEvent("pending", "completed");
      await handler(event);
      expect(mockRunTransaction).toHaveBeenCalledTimes(1);
    });

    it("ignores 'cancelled' status", async () => {
      const event = makeEvent("pending", "cancelled");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("ignores 'refunded' status", async () => {
      const event = makeEvent("pending", "refunded");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("ignores 'pending' status", async () => {
      const event = makeEvent("created", "pending");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("ignores undefined new status", async () => {
      const event = makeEvent("pending", undefined);
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });
  });

  describe("idempotency", () => {
    it("does not increment if previous status was already 'delivered'", async () => {
      const event = makeEvent("delivered", "delivered");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("does not increment if previous status was already 'completed'", async () => {
      const event = makeEvent("completed", "completed");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("does not increment if transitioning from 'delivered' to 'completed'", async () => {
      const event = makeEvent("delivered", "completed");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });

    it("does not increment if transitioning from 'completed' to 'delivered'", async () => {
      const event = makeEvent("completed", "delivered");
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });
  });

  describe("missing uid handling", () => {
    it("does not increment if uid is missing from order", async () => {
      const event = {
        data: {
          before: { data: () => ({ status: "pending" }) },
          after: { data: () => ({ status: "delivered" }) }, // no uid
        },
        params: { orderId: "order-002" },
      };
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });
  });

  describe("missing event data", () => {
    it("handles missing before/after data gracefully", async () => {
      const event = {
        data: { before: { data: () => null }, after: { data: () => null } },
        params: { orderId: "order-003" },
      };
      await handler(event);
      expect(mockRunTransaction).not.toHaveBeenCalled();
    });
  });
});
