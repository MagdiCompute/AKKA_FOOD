import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * Maximum number of OTP requests allowed per identifier (phone or email)
 * within a rolling 1-hour window.
 *
 * Satisfies Requirement 11, Criteria 5.
 */
const MAX_OTP_REQUESTS_PER_HOUR = 5;

export interface OtpRateLimitStatus {
  isRateLimited: boolean;
  requestCount: number;
  resetAt: Date | null;
}

/**
 * checkAndIncrementOtpRateLimit
 *
 * Checks and atomically increments the OTP request count for an identifier
 * (phone number or email address). Returns whether the request is rate-limited.
 *
 * The rate-limit window is a rolling 1-hour period starting from the first
 * request in the current window. Once the window expires (> 1 hour since
 * windowStart), the counter resets.
 *
 * Documents are stored in /otp_rate_limits/{sanitisedIdentifier}.
 * The collection is write-protected by Firestore Security Rules — only the
 * server SDK (Cloud Functions) may read or write it.
 *
 * Satisfies Requirement 11, Criteria 5.
 *
 * @param identifier - Phone number (E.164) or email address to rate-limit.
 * @returns OtpRateLimitStatus indicating whether the request is allowed.
 */
export async function checkAndIncrementOtpRateLimit(
  identifier: string
): Promise<OtpRateLimitStatus> {
  // Sanitise the identifier to produce a valid Firestore document ID.
  // Replace any character that is not alphanumeric with an underscore.
  const docId = identifier.replace(/[^a-zA-Z0-9]/g, "_");

  const ref = admin
    .firestore()
    .collection("otp_rate_limits")
    .doc(docId);

  return admin.firestore().runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);

    // First request ever for this identifier — create the document.
    if (!doc.exists) {
      tx.set(ref, {
        identifier,
        requestCount: 1,
        windowStart: now,
        lastRequest: now,
      });
      return { isRateLimited: false, requestCount: 1, resetAt: null };
    }

    const data = doc.data()!;
    const windowStart: Date = data.windowStart.toDate();

    // The current window has expired — reset the counter and start a new window.
    if (windowStart < oneHourAgo) {
      tx.update(ref, {
        requestCount: 1,
        windowStart: now,
        lastRequest: now,
      });
      return { isRateLimited: false, requestCount: 1, resetAt: null };
    }

    // Still within the current window — check the count.
    const currentCount: number = data.requestCount ?? 0;
    const newCount = currentCount + 1;

    if (newCount > MAX_OTP_REQUESTS_PER_HOUR) {
      // Rate limit exceeded — do NOT increment; return the time the window resets.
      const resetAt = new Date(windowStart.getTime() + 60 * 60 * 1000);
      return {
        isRateLimited: true,
        requestCount: currentCount,
        resetAt,
      };
    }

    // Within limit — increment and allow.
    tx.update(ref, { requestCount: newCount, lastRequest: now });
    return { isRateLimited: false, requestCount: newCount, resetAt: null };
  });
}

/**
 * checkOtpRateLimit
 *
 * HTTPS callable Cloud Function that checks the OTP rate limit for a given
 * identifier (phone number or email address) and increments the counter if
 * the request is allowed.
 *
 * Request data:
 *   - identifier: string — phone number (E.164) or email address
 *
 * Returns:
 *   - { isRateLimited, requestCount, resetAt }
 *
 * Satisfies Requirement 11, Criteria 5.
 */
export const checkOtpRateLimit = functions.https.onCall(
  async (data, _context) => {
    const identifier: string = data.identifier;

    if (!identifier || typeof identifier !== "string" || identifier.trim() === "") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "identifier is required and must be a non-empty string"
      );
    }

    const status = await checkAndIncrementOtpRateLimit(identifier.trim());

    return {
      isRateLimited: status.isRateLimited,
      requestCount: status.requestCount,
      resetAt: status.resetAt?.toISOString() ?? null,
    };
  }
);
