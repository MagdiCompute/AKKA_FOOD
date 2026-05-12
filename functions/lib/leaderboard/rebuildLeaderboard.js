"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.rebuildLeaderboard = void 0;
exports.getMonthlyDocId = getMonthlyDocId;
exports.getWeeklyDocId = getWeeklyDocId;
exports.getIsoWeekNumber = getIsoWeekNumber;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const pubsub_1 = require("firebase-functions/v2/pubsub");
/**
 * rebuildLeaderboard — Pub/Sub Cloud Function
 *
 * Triggered by a message on the `rebuild-leaderboard` topic (published after
 * score increments in `onOrderCompletedLeaderboard`).
 *
 * For each period (allTime, monthly, weekly):
 * 1. Queries `/userScores` where `leaderboardVisible == true`, ordered by the
 *    relevant score field descending, limited to 100.
 * 2. Fetches display name and avatar from `/users/{uid}`.
 * 3. Writes sorted entries array to the corresponding `/leaderboard/{period}` document.
 *
 * Validates:
 * - Req 1 AC1: Return top 100 entries ranked by Score descending
 * - Req 4 AC2: Exclude opted-out users from leaderboard responses
 * - Req 4 AC3: Re-rank without gaps when users opt out
 */
exports.rebuildLeaderboard = (0, pubsub_1.onMessagePublished)("rebuild-leaderboard", async () => {
    const db = admin.firestore();
    const now = new Date();
    functions.logger.info("Rebuilding leaderboard for all periods", {
        timestamp: now.toISOString(),
    });
    const periods = [
        {
            scoreField: "allTimeScore",
            docId: "all_time",
        },
        {
            scoreField: "monthlyScore",
            docId: getMonthlyDocId(now),
        },
        {
            scoreField: "weeklyScore",
            docId: getWeeklyDocId(now),
        },
    ];
    for (const period of periods) {
        try {
            await rebuildPeriod(db, period.scoreField, period.docId);
        }
        catch (error) {
            functions.logger.error(`Failed to rebuild leaderboard for period: ${period.docId}`, {
                docId: period.docId,
                scoreField: period.scoreField,
                error: error instanceof Error ? error.message : String(error),
                timestamp: new Date().toISOString(),
            });
            // Continue with other periods even if one fails
        }
    }
    functions.logger.info("Leaderboard rebuild complete", {
        periods: periods.map((p) => p.docId),
        timestamp: new Date().toISOString(),
    });
});
/**
 * Rebuilds a single leaderboard period document.
 *
 * Queries top 100 visible users by the given score field, fetches their
 * profile data, and writes the sorted entries to the leaderboard document.
 */
async function rebuildPeriod(db, scoreField, docId) {
    // Query top 100 visible users ordered by score descending
    const scoresSnap = await db
        .collection("userScores")
        .where("leaderboardVisible", "==", true)
        .orderBy(scoreField, "desc")
        .limit(100)
        .get();
    if (scoresSnap.empty) {
        functions.logger.info(`No visible users for period: ${docId}`, {
            docId,
            timestamp: new Date().toISOString(),
        });
        // Write empty entries to clear stale data
        await db.doc(`leaderboard/${docId}`).set({
            entries: [],
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
    }
    // Fetch user profiles for display name and avatar
    const uids = scoresSnap.docs.map((doc) => doc.id);
    const userProfiles = await fetchUserProfiles(db, uids);
    // Build sorted entries array
    const entries = scoresSnap.docs.map((doc) => {
        const data = doc.data();
        const uid = doc.id;
        const profile = userProfiles.get(uid);
        return {
            uid,
            displayName: (profile === null || profile === void 0 ? void 0 : profile.displayName) || "",
            avatarUrl: (profile === null || profile === void 0 ? void 0 : profile.avatarUrl) || null,
            score: data[scoreField] || 0,
        };
    });
    // Write to leaderboard document using batch for efficiency
    const batch = db.batch();
    const leaderboardRef = db.doc(`leaderboard/${docId}`);
    batch.set(leaderboardRef, {
        entries,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();
    functions.logger.info(`Leaderboard rebuilt for period: ${docId}`, {
        docId,
        entryCount: entries.length,
        topScore: entries.length > 0 ? entries[0].score : 0,
        timestamp: new Date().toISOString(),
    });
}
/**
 * Fetches user profiles (displayName, avatarUrl) for a list of UIDs.
 * Returns a Map keyed by UID.
 *
 * Handles missing profiles gracefully — returns empty string for displayName
 * and null for avatarUrl if the user document doesn't exist.
 */
async function fetchUserProfiles(db, uids) {
    const profiles = new Map();
    // Firestore getAll supports up to 100 documents in a single call
    const userRefs = uids.map((uid) => db.doc(`users/${uid}`));
    const userSnaps = await db.getAll(...userRefs);
    for (const snap of userSnaps) {
        if (snap.exists) {
            const data = snap.data();
            profiles.set(snap.id, {
                displayName: data.displayName || data.name || "",
                avatarUrl: data.avatarUrl || data.photoUrl || null,
            });
        }
        else {
            profiles.set(snap.id, {
                displayName: "",
                avatarUrl: null,
            });
        }
    }
    return profiles;
}
// ─── Date Helpers ─────────────────────────────────────────────────────────────
/**
 * Returns the monthly leaderboard document ID.
 * Format: `monthly_YYYY_MM` (zero-padded month).
 */
function getMonthlyDocId(date) {
    const year = date.getFullYear().toString();
    const month = (date.getMonth() + 1).toString().padStart(2, "0");
    return `monthly_${year}_${month}`;
}
/**
 * Returns the weekly leaderboard document ID.
 * Format: `weekly_YYYY_WW` (zero-padded ISO 8601 week number).
 *
 * Mirrors the Dart `LeaderboardPaths._isoWeekNumber` logic:
 * - ISO weeks start on Monday
 * - Week 1 is the week containing the first Thursday of the year
 */
function getWeeklyDocId(date) {
    const year = date.getFullYear().toString();
    const week = getIsoWeekNumber(date).toString().padStart(2, "0");
    return `weekly_${year}_${week}`;
}
/**
 * Computes the ISO 8601 week number for the given date.
 *
 * ISO weeks start on Monday. Week 1 is the week containing the first
 * Thursday of the year.
 *
 * This mirrors the Dart implementation in `LeaderboardPaths._isoWeekNumber`.
 */
function getIsoWeekNumber(date) {
    // Create a copy to avoid mutating the original
    const d = new Date(date.getTime());
    // Set to nearest Thursday: current date + 4 - current day number
    // (Sunday = 0, Monday = 1, ..., Saturday = 6)
    // ISO day: Monday = 1, ..., Sunday = 7
    const dayOfWeek = d.getDay() || 7; // Convert Sunday from 0 to 7
    d.setDate(d.getDate() + 4 - dayOfWeek); // Set to Thursday of current week
    // Get January 4th of the Thursday's year (Jan 4 is always in week 1)
    const jan4 = new Date(d.getFullYear(), 0, 4);
    const jan4DayOfWeek = jan4.getDay() || 7;
    // Set Jan 4 to its week's Thursday
    jan4.setDate(jan4.getDate() + 4 - jan4DayOfWeek);
    // Calculate the difference in days and derive week number
    const diffMs = d.getTime() - jan4.getTime();
    const diffDays = Math.round(diffMs / (24 * 60 * 60 * 1000));
    return Math.floor(diffDays / 7) + 1;
}
//# sourceMappingURL=rebuildLeaderboard.js.map