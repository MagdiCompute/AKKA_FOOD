"use strict";
/**
 * Unit tests for computeRecommendations HTTPS Callable.
 *
 * Validates:
 * - Req 1 AC1: Personalized recommendations for users with >= 3 orders
 * - Req 2 AC1: Popularity-based recommendations for users with < 3 orders
 * - Req 3 AC2: Cache with 60-minute TTL
 * - Authentication requirement
 */
Object.defineProperty(exports, "__esModule", { value: true });
// ── Mock firebase-admin ──────────────────────────────────────────────────────
const mockGet = jest.fn();
const mockSet = jest.fn();
const mockGetAll = jest.fn();
const mockDoc = jest.fn(() => ({ get: mockGet, set: mockSet }));
const mockWhere = jest.fn();
const mockOrderBy = jest.fn();
const mockLimit = jest.fn();
const mockCollectionGet = jest.fn();
// Chain: collection().where().where().get()
// Chain: collection().where().orderBy().limit().get()
mockWhere.mockReturnThis();
mockOrderBy.mockReturnThis();
mockLimit.mockReturnValue({ get: mockCollectionGet });
const mockCollection = jest.fn(() => ({
    where: mockWhere,
    orderBy: mockOrderBy,
    limit: mockLimit,
    get: mockCollectionGet,
}));
const mockFirestore = jest.fn(() => ({
    doc: mockDoc,
    collection: mockCollection,
    getAll: mockGetAll,
}));
jest.mock("firebase-admin", () => ({
    firestore: Object.assign(mockFirestore, {
        FieldValue: { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") },
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
// ── Mock firebase-functions/v2/https ─────────────────────────────────────────
jest.mock("firebase-functions/v2/https", () => ({
    onCall: (handler) => handler,
    HttpsError: class HttpsError extends Error {
        constructor(code, message) {
            super(message);
            this.code = code;
        }
    },
}));
// ── Import AFTER mocks ───────────────────────────────────────────────────────
const computeRecommendations_1 = require("./computeRecommendations");
const computeRecommendations_2 = require("./computeRecommendations");
// The export is the raw handler function due to our mock of onCall
const handler = computeRecommendations_1.computeRecommendations;
// ── Test helpers ─────────────────────────────────────────────────────────────
function makeRequest(auth, data = {}) {
    return { auth, data };
}
function makeCacheSnapshot(exists, data) {
    return {
        exists,
        data: () => data,
    };
}
function makeOrderDocs(orders) {
    const defaultCompletedAt = Date.now() - 7 * 24 * 60 * 60 * 1000; // 7 days ago by default
    return {
        docs: orders.map((order) => ({
            id: order.id,
            data: () => ({
                items: order.items,
                uid: "test-uid",
                status: "delivered",
                completedAt: { toMillis: () => { var _a; return (_a = order.completedAt) !== null && _a !== void 0 ? _a : defaultCompletedAt; } },
            }),
        })),
    };
}
function makeMealDocs(mealIds) {
    return {
        docs: mealIds.map((id) => ({
            id,
            data: () => ({ popularityScore: 10, isAvailable: true }),
        })),
    };
}
/**
 * Creates mock document snapshots for db.getAll() availability checks.
 * Each meal is available by default unless specified otherwise.
 */
function makeMealAvailabilityDocs(mealIds, unavailableIds = []) {
    return mealIds.map((id) => ({
        id,
        exists: true,
        data: () => ({
            isAvailable: !unavailableIds.includes(id),
        }),
    }));
}
// ── Tests ────────────────────────────────────────────────────────────────────
describe("computeRecommendations", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        // Reset chain mocks
        mockWhere.mockReturnThis();
        mockOrderBy.mockReturnThis();
        mockLimit.mockReturnValue({ get: mockCollectionGet });
        mockCollection.mockReturnValue({
            where: mockWhere,
            orderBy: mockOrderBy,
            limit: mockLimit,
            get: mockCollectionGet,
        });
        // Default: getAll returns all meals as available
        mockGetAll.mockResolvedValue([]);
    });
    // ────────────────────────────────────────────────────────────────────────
    // Authentication
    // ────────────────────────────────────────────────────────────────────────
    it("throws unauthenticated when auth is undefined", async () => {
        await expect(handler(makeRequest(undefined))).rejects.toMatchObject({
            code: "unauthenticated",
        });
    });
    // ────────────────────────────────────────────────────────────────────────
    // Cache — fresh cache served
    // ────────────────────────────────────────────────────────────────────────
    it("returns cached data when cache is fresh (< 60 min)", async () => {
        const freshTimestamp = Date.now() - 30 * 60 * 1000; // 30 minutes ago
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(true, {
            mealIds: ["meal-1", "meal-2"],
            isPersonalized: true,
            computedAt: { toMillis: () => freshTimestamp },
        }));
        const result = await handler(makeRequest({ uid: "user-1" }));
        expect(result).toEqual({
            mealIds: ["meal-1", "meal-2"],
            isPersonalized: true,
        });
        // Should not query orders since cache is fresh
        expect(mockCollection).not.toHaveBeenCalled();
    });
    // ────────────────────────────────────────────────────────────────────────
    // Cache — stale cache triggers recomputation
    // ────────────────────────────────────────────────────────────────────────
    it("recomputes when cache is stale (> 60 min)", async () => {
        const staleTimestamp = Date.now() - 90 * 60 * 1000; // 90 minutes ago
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(true, {
            mealIds: ["old-meal"],
            isPersonalized: false,
            computedAt: { toMillis: () => staleTimestamp },
        }));
        // Orders query returns < 3 orders → cold start
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([
            { id: "order-1", items: [{ mealId: "meal-a" }] },
        ]));
        // Popular meals query
        mockCollectionGet.mockResolvedValueOnce(makeMealDocs(["pop-1", "pop-2", "pop-3"]));
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "user-2" }));
        expect(result).toEqual({
            mealIds: ["pop-1", "pop-2", "pop-3"],
            isPersonalized: false,
        });
        expect(mockSet).toHaveBeenCalledWith({
            mealIds: ["pop-1", "pop-2", "pop-3"],
            isPersonalized: false,
            computedAt: "SERVER_TIMESTAMP",
        });
    });
    // ────────────────────────────────────────────────────────────────────────
    // Cache miss — no cache document
    // ────────────────────────────────────────────────────────────────────────
    it("computes recommendations when no cache exists", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        // Orders query returns >= 3 orders → personalized (7 days ago)
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([
            { id: "order-1", items: [{ mealId: "meal-a" }] },
            { id: "order-2", items: [{ mealId: "meal-b" }] },
            { id: "order-3", items: [{ mealId: "meal-c" }] },
        ]));
        // getAll for availability check — all available
        mockGetAll.mockResolvedValueOnce(makeMealAvailabilityDocs(["meal-a", "meal-b", "meal-c"]));
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "user-3" }));
        expect(result).toEqual({
            mealIds: expect.arrayContaining(["meal-a", "meal-b", "meal-c"]),
            isPersonalized: true,
        });
        expect(mockDoc).toHaveBeenCalledWith("recommendations/user-3");
    });
    // ────────────────────────────────────────────────────────────────────────
    // Cold start — fewer than 3 orders
    // ────────────────────────────────────────────────────────────────────────
    it("returns popularity-based meals for users with < 3 orders", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        // Orders query returns 0 orders
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([]));
        // Popular meals query
        mockCollectionGet.mockResolvedValueOnce(makeMealDocs(["pop-1", "pop-2", "pop-3", "pop-4", "pop-5"]));
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "new-user" }));
        expect(result).toEqual({
            mealIds: ["pop-1", "pop-2", "pop-3", "pop-4", "pop-5"],
            isPersonalized: false,
        });
    });
    it("returns empty array when no available meals exist (cold start)", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        // Orders query returns 0 orders → cold start
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([]));
        // Popular meals query returns no results
        mockCollectionGet.mockResolvedValueOnce({ docs: [] });
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "empty-user" }));
        expect(result).toEqual({
            mealIds: [],
            isPersonalized: false,
        });
    });
    it("returns fewer than 10 meals when not enough are available (cold start)", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        // Orders query returns 2 orders → cold start
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([
            { id: "o1", items: [{ mealId: "m1" }] },
            { id: "o2", items: [{ mealId: "m2" }] },
        ]));
        // Popular meals query returns only 3 meals
        mockCollectionGet.mockResolvedValueOnce(makeMealDocs(["pop-a", "pop-b", "pop-c"]));
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "few-meals-user" }));
        expect(result).toEqual({
            mealIds: ["pop-a", "pop-b", "pop-c"],
            isPersonalized: false,
        });
        expect(result.mealIds.length).toBe(3);
    });
    // ────────────────────────────────────────────────────────────────────────
    // Personalized — >= 3 orders
    // ────────────────────────────────────────────────────────────────────────
    it("returns personalized meals for users with >= 3 orders", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        // Orders query returns 4 orders (7 days ago by default)
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([
            { id: "o1", items: [{ mealId: "m1" }, { mealId: "m2" }] },
            { id: "o2", items: [{ mealId: "m1" }, { mealId: "m3" }] },
            { id: "o3", items: [{ mealId: "m2" }, { mealId: "m4" }] },
            { id: "o4", items: [{ mealId: "m5" }] },
        ]));
        // getAll for availability check — all available
        mockGetAll.mockResolvedValueOnce(makeMealAvailabilityDocs(["m1", "m2", "m3", "m4", "m5"]));
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "power-user" }));
        expect(result.isPersonalized).toBe(true);
        expect(result.mealIds).toEqual(expect.arrayContaining(["m1", "m2", "m3", "m4", "m5"]));
        expect(result.mealIds.length).toBeLessThanOrEqual(10);
    });
    // ────────────────────────────────────────────────────────────────────────
    // Cache write — result is persisted
    // ────────────────────────────────────────────────────────────────────────
    it("writes computed result to /recommendations/{uid}", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([
            { id: "o1", items: [{ mealId: "m1" }] },
            { id: "o2", items: [{ mealId: "m2" }] },
            { id: "o3", items: [{ mealId: "m3" }] },
        ]));
        // getAll for availability check — all available
        mockGetAll.mockResolvedValueOnce(makeMealAvailabilityDocs(["m1", "m2", "m3"]));
        mockSet.mockResolvedValueOnce(undefined);
        await handler(makeRequest({ uid: "cache-user" }));
        expect(mockDoc).toHaveBeenCalledWith("recommendations/cache-user");
        expect(mockSet).toHaveBeenCalledWith(expect.objectContaining({
            isPersonalized: true,
            computedAt: "SERVER_TIMESTAMP",
        }));
    });
    // ────────────────────────────────────────────────────────────────────────
    // Fill-up logic — personalized results < 3 filled with popular meals
    // Validates: Req 1 AC5
    // ────────────────────────────────────────────────────────────────────────
    it("fills with popular meals when personalized results < 3 (user has >= 3 orders)", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        // User has 3 orders but all meals were ordered in last 24h except 2
        const recentTime = Date.now() - 12 * 60 * 60 * 1000; // 12 hours ago (excluded)
        const oldTime = Date.now() - 7 * 24 * 60 * 60 * 1000; // 7 days ago (included)
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([
            { id: "o1", items: [{ mealId: "m1" }], completedAt: oldTime },
            { id: "o2", items: [{ mealId: "m2" }], completedAt: oldTime },
            { id: "o3", items: [{ mealId: "m3" }], completedAt: recentTime }, // excluded (last 24h)
        ]));
        // getAll for availability check — m1 and m2 available (m3 excluded by scoring)
        mockGetAll.mockResolvedValueOnce(makeMealAvailabilityDocs(["m1", "m2"]));
        // Popular meals query for fill-up
        mockCollectionGet.mockResolvedValueOnce(makeMealDocs(["pop-1", "pop-2", "pop-3", "pop-4", "pop-5", "pop-6", "pop-7", "pop-8", "pop-9", "pop-10"]));
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "fillup-user" }));
        expect(result.isPersonalized).toBe(true);
        // Should have 2 personalized + 8 popular = 10 total
        expect(result.mealIds).toContain("m1");
        expect(result.mealIds).toContain("m2");
        expect(result.mealIds.length).toBe(10);
        // Popular meals should fill the remaining slots
        expect(result.mealIds).toContain("pop-1");
    });
    it("does NOT trigger fill-up when personalized results >= 3", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        // User has 5 orders with 5 distinct meals (all 7 days ago)
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([
            { id: "o1", items: [{ mealId: "m1" }] },
            { id: "o2", items: [{ mealId: "m2" }] },
            { id: "o3", items: [{ mealId: "m3" }] },
            { id: "o4", items: [{ mealId: "m4" }] },
            { id: "o5", items: [{ mealId: "m5" }] },
        ]));
        // getAll for availability check — all available
        mockGetAll.mockResolvedValueOnce(makeMealAvailabilityDocs(["m1", "m2", "m3", "m4", "m5"]));
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "no-fillup-user" }));
        expect(result.isPersonalized).toBe(true);
        expect(result.mealIds.length).toBeGreaterThanOrEqual(3);
        // getPopularMeals should NOT have been called (only 1 collection query for orders)
        // The mockCollectionGet should only have been called once (for orders)
        expect(mockCollectionGet).toHaveBeenCalledTimes(1);
    });
    it("fill-up does not include duplicates (meals already in personalized results)", async () => {
        mockGet.mockResolvedValueOnce(makeCacheSnapshot(false));
        const oldTime = Date.now() - 7 * 24 * 60 * 60 * 1000; // 7 days ago
        mockCollectionGet.mockResolvedValueOnce(makeOrderDocs([
            { id: "o1", items: [{ mealId: "m1" }], completedAt: oldTime },
            { id: "o2", items: [{ mealId: "m2" }], completedAt: oldTime },
            { id: "o3", items: [{ mealId: "m3" }], completedAt: Date.now() - 12 * 60 * 60 * 1000 }, // excluded (last 24h)
        ]));
        // getAll for availability check — m1 and m2 available
        mockGetAll.mockResolvedValueOnce(makeMealAvailabilityDocs(["m1", "m2"]));
        // Popular meals include m1 and m2 (already in personalized) plus others
        mockCollectionGet.mockResolvedValueOnce(makeMealDocs(["m1", "m2", "pop-1", "pop-2", "pop-3", "pop-4", "pop-5", "pop-6", "pop-7", "pop-8"]));
        mockSet.mockResolvedValueOnce(undefined);
        const result = await handler(makeRequest({ uid: "dedup-user" }));
        expect(result.isPersonalized).toBe(true);
        // m1 and m2 from personalized, then pop-1 through pop-8 from popular (no duplicates)
        expect(result.mealIds).toContain("m1");
        expect(result.mealIds).toContain("m2");
        expect(result.mealIds).toContain("pop-1");
        // No duplicates — m1 and m2 should appear only once
        const uniqueIds = new Set(result.mealIds);
        expect(uniqueIds.size).toBe(result.mealIds.length);
        // Total should be capped at 10
        expect(result.mealIds.length).toBeLessThanOrEqual(10);
    });
});
// ── Unit tests for getPopularMeals ───────────────────────────────────────────
describe("getPopularMeals", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        mockWhere.mockReturnThis();
        mockOrderBy.mockReturnThis();
        mockLimit.mockReturnValue({ get: mockCollectionGet });
        mockCollection.mockReturnValue({
            where: mockWhere,
            orderBy: mockOrderBy,
            limit: mockLimit,
            get: mockCollectionGet,
        });
    });
    it("queries meals collection with isAvailable == true, ordered by popularityScore desc, limit 10", async () => {
        mockCollectionGet.mockResolvedValueOnce(makeMealDocs(["m1", "m2", "m3"]));
        const result = await (0, computeRecommendations_2.getPopularMeals)();
        expect(mockCollection).toHaveBeenCalledWith("meals");
        expect(mockWhere).toHaveBeenCalledWith("isAvailable", "==", true);
        expect(mockOrderBy).toHaveBeenCalledWith("popularityScore", "desc");
        expect(mockLimit).toHaveBeenCalledWith(10);
        expect(result).toEqual(["m1", "m2", "m3"]);
    });
    it("returns empty array when no meals are available", async () => {
        mockCollectionGet.mockResolvedValueOnce({ docs: [] });
        const result = await (0, computeRecommendations_2.getPopularMeals)();
        expect(result).toEqual([]);
    });
    it("returns up to 10 meal IDs", async () => {
        const tenMeals = Array.from({ length: 10 }, (_, i) => `meal-${i + 1}`);
        mockCollectionGet.mockResolvedValueOnce(makeMealDocs(tenMeals));
        const result = await (0, computeRecommendations_2.getPopularMeals)();
        expect(result).toHaveLength(10);
        expect(result).toEqual(tenMeals);
    });
});
//# sourceMappingURL=computeRecommendations.test.js.map