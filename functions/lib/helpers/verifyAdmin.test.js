"use strict";
/**
 * Unit tests for verifyAdmin helper.
 *
 * Validates: Requirements 1.3
 *
 * These tests mock firebase-admin so no real Firebase project is needed.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const https_1 = require("firebase-functions/v2/https");
// ---- Mock firebase-admin ----
const mockGet = jest.fn();
const mockDoc = jest.fn(() => ({ get: mockGet }));
const mockFirestore = jest.fn(() => ({ doc: mockDoc }));
jest.mock("firebase-admin", () => ({
    firestore: Object.assign(mockFirestore, {
        FieldValue: { serverTimestamp: jest.fn() },
    }),
    apps: [true], // pretend already initialized
    initializeApp: jest.fn(),
}));
// Import AFTER mocks are set up
const verifyAdmin_1 = require("./verifyAdmin");
// Helper to build a minimal auth object
function makeAuth(uid) {
    return {
        uid,
        token: {},
    };
}
// Helper to make mockGet resolve with a Firestore-like snapshot
function makeSnapshot(exists, data) {
    return {
        exists,
        data: () => data,
    };
}
describe("verifyAdmin", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });
    // ------------------------------------------------------------------ //
    // Authentication checks
    // ------------------------------------------------------------------ //
    it("throws unauthenticated when auth is undefined", async () => {
        await expect((0, verifyAdmin_1.verifyAdmin)(undefined)).rejects.toMatchObject({
            code: "unauthenticated",
        });
    });
    it("throws unauthenticated when auth is null", async () => {
        await expect((0, verifyAdmin_1.verifyAdmin)(null)).rejects.toMatchObject({
            code: "unauthenticated",
        });
    });
    it("throws unauthenticated when auth.uid is empty string", async () => {
        await expect((0, verifyAdmin_1.verifyAdmin)({ uid: "", token: {} })).rejects.toMatchObject({
            code: "unauthenticated",
        });
    });
    // ------------------------------------------------------------------ //
    // Firestore document checks
    // ------------------------------------------------------------------ //
    it("throws permission-denied when user document does not exist", async () => {
        mockGet.mockResolvedValueOnce(makeSnapshot(false));
        await expect((0, verifyAdmin_1.verifyAdmin)(makeAuth("uid-no-doc"))).rejects.toMatchObject({
            code: "permission-denied",
            message: "Admins only",
        });
        expect(mockDoc).toHaveBeenCalledWith("users/uid-no-doc");
    });
    it("throws permission-denied when user document has no data", async () => {
        mockGet.mockResolvedValueOnce(makeSnapshot(true, undefined));
        await expect((0, verifyAdmin_1.verifyAdmin)(makeAuth("uid-no-data"))).rejects.toMatchObject({
            code: "permission-denied",
            message: "Admins only",
        });
    });
    it("throws permission-denied when role is 'user'", async () => {
        mockGet.mockResolvedValueOnce(makeSnapshot(true, { role: "user" }));
        await expect((0, verifyAdmin_1.verifyAdmin)(makeAuth("uid-regular-user"))).rejects.toMatchObject({
            code: "permission-denied",
            message: "Admins only",
        });
    });
    it("throws permission-denied when role is missing", async () => {
        mockGet.mockResolvedValueOnce(makeSnapshot(true, { email: "test@test.com" }));
        await expect((0, verifyAdmin_1.verifyAdmin)(makeAuth("uid-no-role"))).rejects.toMatchObject({
            code: "permission-denied",
            message: "Admins only",
        });
    });
    it("throws permission-denied when role is an unexpected value", async () => {
        mockGet.mockResolvedValueOnce(makeSnapshot(true, { role: "superadmin" }));
        await expect((0, verifyAdmin_1.verifyAdmin)(makeAuth("uid-superadmin"))).rejects.toMatchObject({
            code: "permission-denied",
            message: "Admins only",
        });
    });
    // ------------------------------------------------------------------ //
    // Success path
    // ------------------------------------------------------------------ //
    it("resolves without throwing when role is 'admin'", async () => {
        mockGet.mockResolvedValueOnce(makeSnapshot(true, { role: "admin" }));
        await expect((0, verifyAdmin_1.verifyAdmin)(makeAuth("uid-admin"))).resolves.toBeUndefined();
        expect(mockDoc).toHaveBeenCalledWith("users/uid-admin");
        expect(mockGet).toHaveBeenCalledTimes(1);
    });
    // ------------------------------------------------------------------ //
    // Error type checks
    // ------------------------------------------------------------------ //
    it("throws an instance of HttpsError for unauthenticated calls", async () => {
        await expect((0, verifyAdmin_1.verifyAdmin)(undefined)).rejects.toBeInstanceOf(https_1.HttpsError);
    });
    it("throws an instance of HttpsError for non-admin users", async () => {
        mockGet.mockResolvedValueOnce(makeSnapshot(true, { role: "user" }));
        await expect((0, verifyAdmin_1.verifyAdmin)(makeAuth("uid-user"))).rejects.toBeInstanceOf(https_1.HttpsError);
    });
    // ------------------------------------------------------------------ //
    // Firestore path correctness
    // ------------------------------------------------------------------ //
    it("queries the correct Firestore path for the given uid", async () => {
        const uid = "abc123";
        mockGet.mockResolvedValueOnce(makeSnapshot(true, { role: "admin" }));
        await (0, verifyAdmin_1.verifyAdmin)(makeAuth(uid));
        expect(mockDoc).toHaveBeenCalledWith(`users/${uid}`);
    });
});
//# sourceMappingURL=verifyAdmin.test.js.map