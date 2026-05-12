import * as functions from "firebase-functions";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { PubSub } from "@google-cloud/pubsub";

/**
 * onVisibilityChanged
 *
 * Firestore trigger on `/userScores/{uid}` document updates.
 * Fires when the `leaderboardVisible` field changes (true→false or false→true)
 * and publishes a message to the `rebuild-leaderboard` Pub/Sub topic to trigger
 * a full leaderboard rebuild.
 *
 * This ensures:
 * - When a user opts out, they are immediately removed from the leaderboard
 * - When a user opts back in, they are re-added to the leaderboard
 * - Remaining entries are re-ranked without gaps
 *
 * Validates:
 * - Req 4 AC2: Exclude opted-out users from all leaderboard responses
 * - Req 4 AC3: Re-rank without gaps when users opt out
 */
export const onVisibilityChanged = onDocumentUpdated(
  "userScores/{uid}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) {
      functions.logger.warn(
        "onVisibilityChanged: Missing before/after data"
      );
      return;
    }

    const previousVisibility = before.leaderboardVisible as boolean | undefined;
    const newVisibility = after.leaderboardVisible as boolean | undefined;

    // Only trigger if leaderboardVisible actually changed
    if (previousVisibility === newVisibility) {
      return;
    }

    const uid = event.params.uid;

    functions.logger.info(
      "Leaderboard visibility changed — triggering rebuild",
      {
        uid,
        previousVisibility,
        newVisibility,
        timestamp: new Date().toISOString(),
      }
    );

    // Publish rebuild message to trigger full leaderboard rebuild
    try {
      const pubsub = new PubSub();
      const topic = pubsub.topic("rebuild-leaderboard");
      await topic.publishMessage({
        json: {
          uid,
          reason: "visibility_changed",
          previousVisibility,
          newVisibility,
          timestamp: new Date().toISOString(),
        },
      });

      functions.logger.info("Published rebuild-leaderboard message for visibility change", {
        uid,
        newVisibility,
      });
    } catch (error: unknown) {
      functions.logger.error(
        "Failed to publish rebuild-leaderboard message for visibility change",
        {
          uid,
          error: error instanceof Error ? error.message : String(error),
          timestamp: new Date().toISOString(),
        }
      );
      throw error; // Re-throw to trigger Cloud Functions retry
    }
  }
);
