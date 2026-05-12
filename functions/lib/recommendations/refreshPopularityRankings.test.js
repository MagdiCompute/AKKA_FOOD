"use strict";
/**
 * Unit tests for refreshPopularityRankings Cloud Function.
 *
 * Validates:
 * - Req 5 AC3: Recompute global popularity rankings at least once per hour
 *
 * Covers:
 * - Queries top 50 meals by popularityScore descending
 * - Writes mealIds array to /analytics/popularMeals
 * - Includes rankedMeals with name and score for admin dashboard
 * - Sets updatedAt with serverTimestamp
 * - Handles empty meals collection gracefully
 */
Object.defineProperty(exports, "__esModule", { value: true });
// ── Mocks ─────────────────────────────────────────────────────────────────────
const mockSet = jest.fn().mockResolvedValue(undefined);
const mockDoc = jest.fn(() => ({ set: mockSet }));
const mockOrderBy = jest.fn().mockReturnThis();
const mockLimit = jest.fn().mockReturnThis();
const mockGet = jest.fn();
const mockCollection = jest.fn(() => ({
    orderBy: mockOrderBy,
    limit: mockLimit,
    get: mockGet,
}));
const mockFirestore = Object.assign(jest.fn(() => ({
    collection: mockCollection,
    doc: mockDoc,
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
let capturedHandler;
jest.mock("firebase-functions/v2/scheduler", () => ({
    onSchedule: (schedule, handler) => {
        capturedHandler = handler;
        return handler;
    },
}));
// Import AFTER mocks
require("./refreshPopularityRankings");
// ── Helpers ───────────────────────────────────────────────────────────────────
function makeMealDoc(id, name, popularityScore) {
    return {
        id,
        data: () => ({ name, popularityScore, isAvailable: true }),
    };
}
// ── Tests ─────────────────────────────────────────────────────────────────────
describe("refreshPopularityRankings", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });
    it("queries meals collection ordered by popularityScore desc, limit 50", async () => {
        mockGet.mockResolvedValueOnce({ empty: true, docs: [] });
        await capturedHandler();
        expect(mockCollection).toHaveBeenCalledWith("meals");
        expect(mockOrderBy).toHaveBeenCalledWith("popularityScore", "desc");
        expect(mockLimit).toHaveBeenCalledWith(50);
    });
    it("does nothing when no meals are found", async () => {
        mockGet.mockResolvedValueOnce({ empty: true, docs: [] });
        await capturedHandler();
        expect(mockDoc).not.toHaveBeenCalled();
        expect(mockSet).not.toHaveBeenCalled();
        expect(mockLoggerInfo).toHaveBeenCalledWith("No meals found for popularity rankings", expect.objectContaining({ timestamp: expect.any(String) }));
    });
    it("writes top meal IDs to /analytics/popularMeals", async () => {
        const mealDocs = [
            makeMealDoc("meal-1", "Thieboudienne", 150),
            makeMealDoc("meal-2", "Yassa Poulet", 120),
            makeMealDoc("meal-3", "Mafé", 90),
        ];
        mockGet.mockResolvedValueOnce({ empty: false, docs: mealDocs });
        await capturedHandler();
        expect(mockDoc).toHaveBeenCalledWith("analytics/popularMeals");
        expect(mockSet).toHaveBeenCalledWith({
            mealIds: ["meal-1", "meal-2", "meal-3"],
            rankedMeals: [
                { mealId: "meal-1", name: "Thieboudienne", popularityScore: 150 },
                { mealId: "meal-2", name: "Yassa Poulet", popularityScore: 120 },
                { mealId: "meal-3", name: "Mafé", popularityScore: 90 },
            ],
            updatedAt: "SERVER_TIMESTAMP",
        });
    });
    it("uses serverTimestamp for updatedAt field", async () => {
        const mealDocs = [makeMealDoc("meal-1", "Thieboudienne", 100)];
        mockGet.mockResolvedValueOnce({ empty: false, docs: mealDocs });
        await capturedHandler();
        expect(mockSet).toHaveBeenCalledWith(expect.objectContaining({ updatedAt: "SERVER_TIMESTAMP" }));
    });
    it("includes meal names and scores in rankedMeals for admin dashboard", async () => {
        const mealDocs = [
            makeMealDoc("meal-a", "Poulet Braisé", 200),
            makeMealDoc("meal-b", "Attiéké Poisson", 180),
        ];
        mockGet.mockResolvedValueOnce({ empty: false, docs: mealDocs });
        await capturedHandler();
        const setCall = mockSet.mock.calls[0][0];
        expect(setCall.rankedMeals).toEqual([
            { mealId: "meal-a", name: "Poulet Braisé", popularityScore: 200 },
            { mealId: "meal-b", name: "Attiéké Poisson", popularityScore: 180 },
        ]);
    });
    it("handles meals with missing name gracefully", async () => {
        const mealDocs = [
            {
                id: "meal-no-name",
                data: () => ({ popularityScore: 50 }),
            },
        ];
        mockGet.mockResolvedValueOnce({ empty: false, docs: mealDocs });
        await capturedHandler();
        const setCall = mockSet.mock.calls[0][0];
        expect(setCall.rankedMeals[0]).toEqual({
            mealId: "meal-no-name",
            name: null,
            popularityScore: 50,
        });
    });
    it("handles meals with missing popularityScore gracefully", async () => {
        const mealDocs = [
            {
                id: "meal-no-score",
                data: () => ({ name: "Test Meal" }),
            },
        ];
        mockGet.mockResolvedValueOnce({ empty: false, docs: mealDocs });
        await capturedHandler();
        const setCall = mockSet.mock.calls[0][0];
        expect(setCall.rankedMeals[0]).toEqual({
            mealId: "meal-no-score",
            name: "Test Meal",
            popularityScore: 0,
        });
    });
    it("logs success with meal count and top meal ID", async () => {
        const mealDocs = [
            makeMealDoc("top-meal", "Best Meal", 500),
            makeMealDoc("second-meal", "Second Best", 400),
        ];
        mockGet.mockResolvedValueOnce({ empty: false, docs: mealDocs });
        await capturedHandler();
        expect(mockLoggerInfo).toHaveBeenCalledWith("Popularity rankings refreshed", expect.objectContaining({
            mealCount: 2,
            topMealId: "top-meal",
            timestamp: expect.any(String),
        }));
    });
});
//# sourceMappingURL=refreshPopularityRankings.test.js.map