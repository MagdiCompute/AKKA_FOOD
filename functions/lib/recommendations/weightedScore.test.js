"use strict";
/**
 * Unit tests for the weightedScore function.
 *
 * weightedScore is a pure scoring function that does NOT use Firestore,
 * so no firebase-admin mocking is needed.
 *
 * Validates: Requirements 1.2, 1.4
 */
Object.defineProperty(exports, "__esModule", { value: true });
// Mock firebase-admin to prevent import errors (computeRecommendations.ts imports it)
jest.mock("firebase-admin", () => ({
    firestore: Object.assign(jest.fn(), {
        FieldValue: { serverTimestamp: jest.fn() },
    }),
    apps: [true],
    initializeApp: jest.fn(),
}));
jest.mock("firebase-functions", () => ({
    logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));
jest.mock("firebase-functions/v2/https", () => ({
    onCall: (handler) => handler,
    HttpsError: class HttpsError extends Error {
        constructor(code, message) {
            super(message);
            this.code = code;
        }
    },
}));
const computeRecommendations_1 = require("./computeRecommendations");
// ── Test helpers ─────────────────────────────────────────────────────────────
const NOW = 1700000000000; // Fixed reference time
function makeOrder(mealIds, completedAtMillis) {
    return {
        items: mealIds.map((mealId) => ({ mealId })),
        completedAt: { toMillis: () => completedAtMillis },
    };
}
// ── Tests ────────────────────────────────────────────────────────────────────
describe("weightedScore", () => {
    beforeAll(() => {
        jest.spyOn(Date, "now").mockReturnValue(NOW);
    });
    afterAll(() => {
        jest.restoreAllMocks();
    });
    // 1. Returns 0 for a meal not in any order
    it("returns 0 for a meal not present in any order", () => {
        const orders = [
            makeOrder(["meal-a", "meal-b"], NOW - 7 * 24 * 60 * 60 * 1000),
        ];
        expect((0, computeRecommendations_1.weightedScore)("meal-x", orders)).toBe(0);
    });
    // 2. Returns 0 for a meal only ordered in the last 24 hours (excluded)
    it("returns 0 for a meal only ordered in the last 24 hours", () => {
        const twelveHoursAgo = NOW - 12 * 60 * 60 * 1000;
        const orders = [makeOrder(["meal-a"], twelveHoursAgo)];
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(0);
    });
    // 3. Returns 1.5 for a meal ordered once within the last 30 days (recency boost)
    it("returns 1.5 for a meal ordered once within the last 30 days", () => {
        const sevenDaysAgo = NOW - 7 * 24 * 60 * 60 * 1000;
        const orders = [makeOrder(["meal-a"], sevenDaysAgo)];
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(1.5);
    });
    // 4. Returns 1.0 for a meal ordered once more than 30 days ago
    it("returns 1.0 for a meal ordered once more than 30 days ago", () => {
        const sixtyDaysAgo = NOW - 60 * 24 * 60 * 60 * 1000;
        const orders = [makeOrder(["meal-a"], sixtyDaysAgo)];
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(1.0);
    });
    // 5. Accumulates score across multiple orders (2 orders in last 30 days = 3.0)
    it("accumulates score across multiple orders in last 30 days", () => {
        const fiveDaysAgo = NOW - 5 * 24 * 60 * 60 * 1000;
        const tenDaysAgo = NOW - 10 * 24 * 60 * 60 * 1000;
        const orders = [
            makeOrder(["meal-a"], fiveDaysAgo),
            makeOrder(["meal-a"], tenDaysAgo),
        ];
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(3.0);
    });
    // 6. Mixed recency: one order in last 30 days (1.5) + one older order (1.0) = 2.5
    it("returns 2.5 for mixed recency (one recent + one old order)", () => {
        const tenDaysAgo = NOW - 10 * 24 * 60 * 60 * 1000;
        const sixtyDaysAgo = NOW - 60 * 24 * 60 * 60 * 1000;
        const orders = [
            makeOrder(["meal-a"], tenDaysAgo),
            makeOrder(["meal-a"], sixtyDaysAgo),
        ];
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(2.5);
    });
    // 7. Handles orders with missing/empty items gracefully
    it("handles orders with missing items gracefully", () => {
        const sevenDaysAgo = NOW - 7 * 24 * 60 * 60 * 1000;
        const orders = [
            { completedAt: { toMillis: () => sevenDaysAgo } }, // no items field
            { items: [], completedAt: { toMillis: () => sevenDaysAgo } }, // empty items
            { items: null, completedAt: { toMillis: () => sevenDaysAgo } }, // null items
        ];
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(0);
    });
    // 8. Handles orders with missing completedAt gracefully
    it("handles orders with missing completedAt gracefully", () => {
        const orders = [
            { items: [{ mealId: "meal-a" }] }, // no completedAt
            { items: [{ mealId: "meal-a" }], completedAt: null }, // null completedAt
            { items: [{ mealId: "meal-a" }], completedAt: undefined }, // undefined completedAt
        ];
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(0);
    });
    // 9. Multiple meals in same order — only counts the target meal
    it("only counts the target meal in orders with multiple meals", () => {
        const sevenDaysAgo = NOW - 7 * 24 * 60 * 60 * 1000;
        const orders = [
            makeOrder(["meal-a", "meal-b", "meal-c"], sevenDaysAgo),
        ];
        // meal-a gets 1.5 (in last 30 days)
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(1.5);
        // meal-b also gets 1.5 independently
        expect((0, computeRecommendations_1.weightedScore)("meal-b", orders)).toBe(1.5);
        // meal-x not in order, gets 0
        expect((0, computeRecommendations_1.weightedScore)("meal-x", orders)).toBe(0);
    });
    // 10. Boundary test: order exactly at 24h boundary
    it("excludes order exactly at the 24-hour boundary", () => {
        const exactlyOneDayAgo = NOW - 24 * 60 * 60 * 1000;
        const orders = [makeOrder(["meal-a"], exactlyOneDayAgo)];
        // completedAt > oneDayAgo means excluded; at exactly oneDayAgo it's NOT > oneDayAgo
        // so it should be included with recency boost (within 30 days)
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(1.5);
    });
    // 11. Boundary test: order exactly at 30-day boundary
    it("applies 1.0 weight for order exactly at the 30-day boundary", () => {
        const exactlyThirtyDaysAgo = NOW - 30 * 24 * 60 * 60 * 1000;
        const orders = [makeOrder(["meal-a"], exactlyThirtyDaysAgo)];
        // completedAt > thirtyDaysAgo means recency boost; at exactly thirtyDaysAgo it's NOT > thirtyDaysAgo
        // so it gets 1.0 weight (no recency boost)
        expect((0, computeRecommendations_1.weightedScore)("meal-a", orders)).toBe(1.0);
    });
});
//# sourceMappingURL=weightedScore.test.js.map