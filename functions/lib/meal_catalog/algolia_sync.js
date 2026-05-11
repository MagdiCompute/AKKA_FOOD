"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a, _b;
Object.defineProperty(exports, "__esModule", { value: true });
exports.onMealDeleted = exports.onMealUpdated = exports.onMealCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const algoliasearch_1 = __importDefault(require("algoliasearch"));
const ALGOLIA_APP_ID = (_a = process.env.ALGOLIA_APP_ID) !== null && _a !== void 0 ? _a : "";
const ALGOLIA_ADMIN_API_KEY = (_b = process.env.ALGOLIA_ADMIN_API_KEY) !== null && _b !== void 0 ? _b : "";
const ALGOLIA_INDEX_NAME = "meals";
/**
 * Lazily initialise the Algolia client so the module can be imported in tests
 * without requiring real credentials.
 */
function getAlgoliaIndex() {
    const client = (0, algoliasearch_1.default)(ALGOLIA_APP_ID, ALGOLIA_ADMIN_API_KEY);
    return client.initIndex(ALGOLIA_INDEX_NAME);
}
/**
 * onMealCreated
 *
 * Triggered when a new document is created in /meals/{mealId}.
 * Indexes the new meal in Algolia.
 */
exports.onMealCreated = (0, firestore_1.onDocumentCreated)("meals/{mealId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const meal = snap.data();
    const mealId = event.params.mealId;
    const index = getAlgoliaIndex();
    await index.saveObject(Object.assign(Object.assign({}, meal), { objectID: mealId }));
});
/**
 * onMealUpdated
 *
 * Triggered when an existing document in /meals/{mealId} is updated.
 * Updates the corresponding Algolia record.
 */
exports.onMealUpdated = (0, firestore_1.onDocumentUpdated)("meals/{mealId}", async (event) => {
    var _a;
    const afterSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after;
    if (!afterSnap)
        return;
    const meal = afterSnap.data();
    const mealId = event.params.mealId;
    const index = getAlgoliaIndex();
    await index.saveObject(Object.assign(Object.assign({}, meal), { objectID: mealId }));
});
/**
 * onMealDeleted
 *
 * Triggered when a document is deleted from /meals/{mealId}.
 * Removes the corresponding record from the Algolia index.
 */
exports.onMealDeleted = (0, firestore_1.onDocumentDeleted)("meals/{mealId}", async (event) => {
    const mealId = event.params.mealId;
    const index = getAlgoliaIndex();
    await index.deleteObject(mealId);
});
//# sourceMappingURL=algolia_sync.js.map