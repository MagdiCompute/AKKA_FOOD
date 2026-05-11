import * as admin from "firebase-admin";

const MAX_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

export interface LockStatus {
  isLocked: boolean;
  lockedUntil: Date | null;
  failedAttempts: number;
}

/**
 * recordFailedAttempt
 *
 * Records a failed login attempt for the given uid.
 * If attempts reach MAX_ATTEMPTS within the window, locks the account
 * for 15 minutes and resets the counter (Requirement 4.4).
 *
 * @param uid - The Firebase Auth user UID
 */
export async function recordFailedAttempt(uid: string): Promise<void> {
  const ref = admin.firestore().collection("users").doc(uid);
  await admin.firestore().runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (!doc.exists) return;
    const data = doc.data()!;
    const attempts = (data["failedLoginAttempts"] ?? 0) + 1;
    const update: Record<string, unknown> = { failedLoginAttempts: attempts };
    if (attempts >= MAX_ATTEMPTS) {
      update["lockedUntil"] = new Date(Date.now() + LOCKOUT_DURATION_MS);
      update["failedLoginAttempts"] = 0; // reset after locking
    }
    tx.update(ref, update);
  });
}

/**
 * resetFailedAttempts
 *
 * Resets failed login attempts after a successful sign-in (Requirement 4.1).
 *
 * @param uid - The Firebase Auth user UID
 */
export async function resetFailedAttempts(uid: string): Promise<void> {
  await admin.firestore().collection("users").doc(uid).update({
    failedLoginAttempts: 0,
    lockedUntil: null,
  });
}

/**
 * checkLockStatus
 *
 * Checks whether the account is currently locked (Requirement 4.5).
 *
 * @param uid - The Firebase Auth user UID
 * @returns LockStatus with isLocked, lockedUntil, and failedAttempts
 */
export async function checkLockStatus(uid: string): Promise<LockStatus> {
  const doc = await admin.firestore().collection("users").doc(uid).get();
  if (!doc.exists) {
    return { isLocked: false, lockedUntil: null, failedAttempts: 0 };
  }
  const data = doc.data()!;
  const lockedUntil: Date | null = data["lockedUntil"]?.toDate() ?? null;
  const isLocked = lockedUntil !== null && lockedUntil > new Date();
  return {
    isLocked,
    lockedUntil: isLocked ? lockedUntil : null,
    failedAttempts: data["failedLoginAttempts"] ?? 0,
  };
}
