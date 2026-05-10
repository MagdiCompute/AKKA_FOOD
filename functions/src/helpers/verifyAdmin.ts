import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Verifies that the caller of an HTTPS Callable Cloud Function is an admin.
 *
 * Steps:
 *  1. Ensures a Firebase Auth ID token was provided in the call context.
 *  2. Looks up the caller's Firestore document at /users/{uid}.
 *  3. Checks that `role == 'admin'`.
 *
 * Throws `HttpsError('permission-denied', 'Admins only')` if any check fails.
 *
 * @param auth - The `auth` object from a Firebase Functions v2 CallableRequest,
 *               or `undefined` / `null` when the caller is unauthenticated.
 */
export async function verifyAdmin(
  auth: { uid: string; token: admin.auth.DecodedIdToken } | undefined | null
): Promise<void> {
  // 1. Require authentication
  if (!auth || !auth.uid) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // 2. Look up the user document in Firestore
  const db = admin.firestore();
  const userDoc = await db.doc(`users/${auth.uid}`).get();

  if (!userDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Admins only"
    );
  }

  // 3. Check the role field
  const data = userDoc.data();
  if (!data || data["role"] !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Admins only"
    );
  }
}
