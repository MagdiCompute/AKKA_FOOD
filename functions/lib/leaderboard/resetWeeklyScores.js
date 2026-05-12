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
exports.resetWeeklyScores = void 0;
const admin = __importStar(require("firebase-admin"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const functions = __importStar(require("firebase-functions"));
const pubsub_1 = require("@google-cloud/pubsub");
const rebuildLeaderboard_1 = require("./rebuildLeaderboard");
/**
 * resetWeeklyScores — Scheduled Cloud Function
 *
 * Runs every Monday at 00:00 UTC (cron: `0 0 * * 1`).
 * Resets all users' weekly scores to zero and cleans up the previous week's
 * leaderboard document.
 *
 * Steps:
 * 1. Query ALL documents in `/userScores` collection
 * 2. Batch-update `weeklyScore = 0` for all documents (max 500 per batch)
 * 3. Delete the previous week's leaderboard document: `/leaderboard/weekly_{prev_week}`
 * 4. Trigger a leaderboard rebuild via Pub/Sub to update the new week's leaderboard
 *
 * Validates:
 * - Req 3 AC5: Weekly period counts only orders completed within the current
 *   calendar week (Monday to Sunday)
 */
exports.resetWeeklyScores = (0, scheduler_1.onSchedule)("0 0 * * 1", async () => {
    const db = admin.firestore();
    const now = new Date();
    functions.logger.info("Starting weekly score reset", {
        timestamp: now.toISOString(),
    });
    // ── 1. Batch-reset weeklyScore = 0 for all userScores documents ─────────
    let totalReset = 0;
    let lastDoc;
    // Paginate through all userScores documents
    while (true) {
        let query = db
            .collection("userScores")
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(500);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        const snapshot = await query.get();
        if (snapshot.empty) {
            break;
        }
        // Batch update this page of documents
        const batch = db.batch();
        for (const doc of snapshot.docs) {
            batch.update(doc.ref, { weeklyScore: 0 });
        }
        await batch.commit();
        totalReset += snapshot.docs.length;
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        functions.logger.info("Weekly score reset batch committed", {
            batchSize: snapshot.docs.length,
            totalReset,
            timestamp: new Date().toISOString(),
        });
        // If we got fewer than 500 docs, we've reached the end
        if (snapshot.docs.length < 500) {
            break;
        }
    }
    functions.logger.info("All weekly scores reset to zero", {
        totalReset,
        timestamp: new Date().toISOString(),
    });
    // ── 2. Delete previous week's leaderboard document ──────────────────────
    try {
        const prevWeekDocId = getPreviousWeekDocId(now);
        await db.doc(`leaderboard/${prevWeekDocId}`).delete();
        functions.logger.info("Deleted previous week leaderboard document", {
            docId: prevWeekDocId,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        // Non-critical: log but don't fail the function
        functions.logger.warn("Failed to delete previous week leaderboard document", {
            error: error instanceof Error ? error.message : String(error),
            timestamp: new Date().toISOString(),
        });
    }
    // ── 3. Trigger leaderboard rebuild via Pub/Sub ──────────────────────────
    try {
        const pubsub = new pubsub_1.PubSub();
        const topic = pubsub.topic("rebuild-leaderboard");
        await topic.publishMessage({
            json: {
                reason: "weekly_reset",
                timestamp: now.toISOString(),
            },
        });
        functions.logger.info("Published rebuild-leaderboard message after weekly reset", {
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        functions.logger.warn("Failed to publish rebuild-leaderboard message", {
            error: error instanceof Error ? error.message : String(error),
            timestamp: new Date().toISOString(),
        });
    }
    functions.logger.info("Weekly score reset complete", {
        totalReset,
        timestamp: new Date().toISOString(),
    });
});
/**
 * Computes the previous week's leaderboard document ID.
 *
 * Subtracts 7 days from the given date to get a date in the previous week,
 * then uses the shared `getWeeklyDocId` helper to format it.
 */
function getPreviousWeekDocId(date) {
    const prevWeek = new Date(date.getTime());
    prevWeek.setDate(prevWeek.getDate() - 7);
    // Use the year from the ISO week calculation for correctness at year boundaries
    const weekNumber = (0, rebuildLeaderboard_1.getIsoWeekNumber)(prevWeek);
    const year = getIsoWeekYear(prevWeek);
    return `weekly_${year}_${weekNumber.toString().padStart(2, "0")}`;
}
/**
 * Returns the ISO week-numbering year for the given date.
 *
 * The ISO week-numbering year may differ from the calendar year at the
 * boundaries (e.g., Dec 31 might be in week 1 of the next year).
 */
function getIsoWeekYear(date) {
    const d = new Date(date.getTime());
    const dayOfWeek = d.getDay() || 7;
    d.setDate(d.getDate() + 4 - dayOfWeek); // Set to Thursday of current week
    return d.getFullYear();
}
//# sourceMappingURL=resetWeeklyScores.js.map