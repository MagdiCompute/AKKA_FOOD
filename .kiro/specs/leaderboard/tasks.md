# Tasks — Leaderboard

## Task List

- [x] 1. Domain layer — Leaderboard entities
  - [x] 1.1 Create `LeaderboardEntry` entity (rank, uid, displayName, avatarUrl, score, isCurrentUser)
  - [x] 1.2 Create `LeaderboardPeriod` enum (allTime, monthly, weekly)
  - [x] 1.3 Define `ILeaderboardRepository` interface

- [x] 2. Firestore structure
  - [x] 2.1 Create `/leaderboard/all_time` document schema (entries array, updatedAt)
  - [x] 2.2 Create `/leaderboard/monthly_{YYYY_MM}` document schema
  - [x] 2.3 Create `/leaderboard/weekly_{YYYY_WW}` document schema
  - [x] 2.4 Create `/userScores/{uid}` document schema (allTimeScore, monthlyScore, weeklyScore, leaderboardVisible)

- [x] 3. Cloud Functions — Score and ranking
  - [x] 3.1 Implement `onOrderCompleted` Firestore trigger: increment `allTimeScore`, `monthlyScore`, `weeklyScore` in `/userScores/{uid}` atomically; invalidate recommendation cache
  - [x] 3.2 Implement `rebuildLeaderboard` Pub/Sub function: query top 100 visible users by score for each period, write sorted entries to leaderboard documents
  - [x] 3.3 Implement `resetWeeklyScores` scheduled function (every Monday 00:00 UTC): batch-reset `weeklyScore = 0`
  - [x] 3.4 Implement `resetMonthlyScores` scheduled function (1st of month 00:00 UTC): batch-reset `monthlyScore = 0`
  - [x] 3.5 Write unit tests for score calculation and ranking logic

- [x] 4. Data layer — LeaderboardRepository
  - [x] 4.1 Implement `FirestoreLeaderboardDataSource`: real-time listener on leaderboard documents
  - [x] 4.2 Implement current user rank query for users outside top 100
  - [x] 4.3 Implement `LeaderboardRepository`

- [x] 5. State management — LeaderboardNotifier
  - [x] 5.1 Implement `LeaderboardNotifier` (Riverpod): loadLeaderboard(period), getCurrentUserEntry(period)
  - [x] 5.2 Implement period switching with real-time Firestore listener
  - [x] 5.3 Write unit tests for LeaderboardNotifier

- [x] 6. Presentation layer — Leaderboard screen
  - [x] 6.1 Implement `LeaderboardScreen`: period tab bar (All-Time | Monthly | Weekly), scrollable top-100 list
  - [x] 6.2 Implement `LeaderboardEntryTile`: rank number/medal (top 3), avatar, display name, score
  - [x] 6.3 Implement current user highlight: distinct background color on matching entry
  - [x] 6.4 Implement sticky `CurrentUserRankCard` at bottom: always visible rank + score
  - [x] 6.5 Implement "outside top 100" separator and user entry below list
  - [x] 6.6 Implement empty state for new periods with no data

- [x] 7. Privacy settings
  - [x] 7.1 Add `leaderboardVisible` toggle to `NotificationPrefsScreen` (Profile feature)
  - [x] 7.2 Implement Cloud Function: on `leaderboardVisible` change → trigger `rebuildLeaderboard`
  - [x] 7.3 Write Firestore Security Rules: `/userScores/{uid}` writable only by Cloud Functions; readable by matching uid

- [x] 8. Integration testing
  - [x] 8.1 Write integration test: complete order → score incremented → leaderboard updated within 60s
  - [x] 8.2 Write integration test: opt out of leaderboard → entry removed from rankings
  - [x] 8.3 Write integration test: period switching shows correct scores
  - [x] 8.4 Write integration test: weekly reset clears weekly scores
