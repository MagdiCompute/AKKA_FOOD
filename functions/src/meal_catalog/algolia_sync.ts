import { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import algoliasearch from "algoliasearch";

const ALGOLIA_APP_ID = process.env.ALGOLIA_APP_ID ?? "";
const ALGOLIA_ADMIN_API_KEY = process.env.ALGOLIA_ADMIN_API_KEY ?? "";
const ALGOLIA_INDEX_NAME = "meals";

/**
 * Lazily initialise the Algolia client so the module can be imported in tests
 * without requiring real credentials.
 */
function getAlgoliaIndex() {
  const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_API_KEY);
  return client.initIndex(ALGOLIA_INDEX_NAME);
}

/**
 * onMealCreated
 *
 * Triggered when a new document is created in /meals/{mealId}.
 * Indexes the new meal in Algolia.
 */
export const onMealCreated = onDocumentCreated("meals/{mealId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const meal = snap.data() as Record<string, unknown>;
  const mealId = event.params.mealId;

  const index = getAlgoliaIndex();
  await index.saveObject({ ...meal, objectID: mealId });
});

/**
 * onMealUpdated
 *
 * Triggered when an existing document in /meals/{mealId} is updated.
 * Updates the corresponding Algolia record.
 */
export const onMealUpdated = onDocumentUpdated("meals/{mealId}", async (event) => {
  const afterSnap = event.data?.after;
  if (!afterSnap) return;

  const meal = afterSnap.data() as Record<string, unknown>;
  const mealId = event.params.mealId;

  const index = getAlgoliaIndex();
  await index.saveObject({ ...meal, objectID: mealId });
});

/**
 * onMealDeleted
 *
 * Triggered when a document is deleted from /meals/{mealId}.
 * Removes the corresponding record from the Algolia index.
 */
export const onMealDeleted = onDocumentDeleted("meals/{mealId}", async (event) => {
  const mealId = event.params.mealId;

  const index = getAlgoliaIndex();
  await index.deleteObject(mealId);
});
