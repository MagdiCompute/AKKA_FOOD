# Tasks — Leaderboard

## Task List

- [x] 1. Domain layer — Leaderboard entities
  - [x] 1.1 Create `LeaderboardEntry` entity (rank, uid, displayName, avatarUrl, score, isCurrentUser)
  - [x] 1.2 Create `LeaderboardPeriod` enum (allTime, monthly, weekly)
  - [x] 1.3 Define `ILeaderboardRepository` interface

- [ ] 2. Firestore structure
  - [ ] 2.1 Create `/leaderboard/all_time` document schema (entries array, updatedAt)
  - [ ] 2.2 Create `/leaderboard/monthly_{YYYY_MM}` document schema
  - [ ] 2.3 Create `/leaderboard/weekly_{YYYY_WW}` document schema
  - [ ] 2.4 Create `/userScores/{uid}` document schema (allTimeScore, monthlyScore, weeklyScore, leaderboardVisible)

- [ ] 3. Cloud Functions — Score and ranking
  - [ ] 3.1 Implement `onOrderCompleted` Firestore trigger: increment `allTimeScore`, `monthlyScore`, `weeklyScore` in `/userScores/{uid}` atomically; invalidate recommendation cache
  - [ ] 3.2 Implement `rebuildLeaderboard` Pub/Sub function: query top 100 visible users by score for each period, write sorted entries to leaderboard documents
  - [ ] 3.3 Implement `resetWeeklyScores` scheduled function (every Monday 00:00 UTC): batch-reset `weeklyScore = 0`
  - [ ] 3.4 Implement `resetMonthlyScores` scheduled function (1st of month 00:00 UTC): batch-reset `monthlyScore = 0`
  - [ ] 3.5 Write unit tests for score calculation and ranking logic

- [ ] 4. Data layer — LeaderboardRepository
  - [ ] 4.1 Implement `FirestoreLeaderboardDataSource`: real-time listener on leaderboard documents
  - [ ] 4.2 Implement current user rank query for users outside top 100
  - [ ] 4.3 Implement `LeaderboardRepository`

- [ ] 5. State management — LeaderboardNotifier
  - [ ] 5.1 Implement `LeaderboardNotifier` (Riverpod): loadLeaderboard(period), getCurrentUserEntry(period)
  - [ ] 5.2 Implement period switching with real-time Firestore listener
  - [ ] 5.3 Write unit tests for LeaderboardNotifier

- [ ] 6. Presentation layer — Leaderboard screen
  - [ ] 6.1 Implement `LeaderboardScreen`: period tab bar (All-Time | Monthly | Weekly), scrollable top-100 list
  - [ ] 6.2 Implement `LeaderboardEntryTile`: rank number/medal (top 3), avatar, display name, score
  - [ ] 6.3 Implement current user highlight: distinct background color on matching entry
  - [ ] 6.4 Implement sticky `CurrentUserRankCard` at bottom: always visible rank + score
  - [ ] 6.5 Implement "outside top 100" separator and user entry below list
  - [ ] 6.6 Implement empty state for new periods with no data

- [ ] 7. Privacy settings
  - [ ] 7.1 Add `leaderboardVisible` toggle to `NotificationPrefsScreen` (Profile feature)
  - [ ] 7.2 Implement Cloud Function: on `leaderboardVisible` change → trigger `rebuildLeaderboard`
  - [ ] 7.3 Write Firestore Security Rules: `/userScores/{uid}` writable only by Cloud Functions; readable by matching uid

- [ ] 8. Integration testing
  - [ ] 8.1 Write integration test: complete order → score incremented → leaderboard updated within 60s
  - [ ] 8.2 Write integration test: opt out of leaderboard → entry removed from rankings
  - [ ] 8.3 Write integration test: period switching shows correct scores
  - [ ] 8.4 Write integration test: weekly reset clears weekly scores
