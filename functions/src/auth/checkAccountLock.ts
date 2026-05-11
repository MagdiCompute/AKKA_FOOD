import * as functions from "firebase-functions";
import {
  checkLockStatus,
  recordFailedAttempt,
  resetFailedAttempts,
} from "./accountLockout";

/**
 * checkAccountLock
 *
 * HTTPS callable function that checks whether a user account is locked
 * before allowing a sign-in attempt (Requirement 4.5).
 *
 * Request data:
 *   - uid: string — the Firebase Auth user UID to check
 *
 * Returns:
 *   - { isLocked, lockedUntil, failedAttempts }
 */
export const checkAccountLock = functions.https.onCall(
  async (data, _context) => {
    const uid: string = data.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required"
      );
    }
    const status = await checkLockStatus(uid);
    return {
      isLocked: status.isLocked,
      lockedUntil: status.lockedUntil?.toISOString() ?? null,
      failedAttempts: status.failedAttempts,
    };
  }
);

/**
 * recordFailedLoginAttempt
 *
 * HTTPS callable function that records a failed login attempt for a uid.
 * Locks the account after MAX_ATTEMPTS consecutive failures (Requirement 4.4).
 *
 * Request data:
 *   - uid: string — the Firebase Auth user UID
 */
export const recordFailedLoginAttempt = functions.https.onCall(
  async (data, _context) => {
    const uid: string = data.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required"
      );
    }
    await recordFailedAttempt(uid);
    return { success: true };
  }
);

/**
 * resetLoginAttempts
 *
 * HTTPS callable function that resets failed login attempts after a
 * successful sign-in (Requirement 4.1).
 *
 * Request data:
 *   - uid: string — the Firebase Auth user UID
 */
export const resetLoginAttempts = functions.https.onCall(
  async (data, _context) => {
    const uid: string = data.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required"
      );
    }
    await resetFailedAttempts(uid);
    return { success: true };
  }
);
