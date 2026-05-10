# Design Document — Leaderboard

## Overview

The Leaderboard uses Firestore aggregation documents updated by Cloud Functions on order completion. Three period views (all-time, monthly, weekly) are maintained as separate Firestore documents for fast reads. Riverpod manages UI state.

---

## Architecture

```
Presentation Layer
  └── Screens: LeaderboardScreen
  └── Widgets: LeaderboardEntryTile, CurrentUserRankCard, PeriodTabBar
  └── State: LeaderboardNotifier (Riverpod)

Domain Layer
  └── Entities: LeaderboardEntry, LeaderboardPeriod
  └── Use Cases: GetLeaderboardUseCase, GetCurrentUserRankUseCase

Data Layer
  └── LeaderboardRepository
  └── FirestoreLeaderboardDataSource
```

---

## Data Models

### LeaderboardEntry
```dart
class LeaderboardEntry {
  final int rank;
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final int score;           // total completed orders for the period
  final bool isCurrentUser;
}

enum LeaderboardPeriod { allTime, monthly, weekly }
```

---

## Firestore Structure

```
/leaderboard/all_time
  - entries: [{ uid, displayName, avatarUrl, score }]  // sorted by score desc, top 100
  - updatedAt: timestamp

/leaderboard/monthly_{YYYY_MM}
  - entries: [{ uid, displayName, avatarUrl, score }]
  - updatedAt: timestamp

/leaderboard/weekly_{YYYY_WW}
  - entries: [{ uid, displayName, avatarUrl, score }]
  - updatedAt: timestamp

/userScores/{uid}
  - allTimeScore: number
  - monthlyScore: number   // reset monthly by scheduled function
  - weeklyScore: number    // reset weekly by scheduled function
  - leaderboardVisible: bool
```

---

## Cloud Functions

### `onOrderCompleted` (Firestore trigger on `/orders/{id}` status → 'delivered')
```javascript
// 1. Increment userScores
await db.runTransaction(async (t) => {
  const scoreRef = db.doc(`userScores/${uid}`);
  const scores = (await t.get(scoreRef)).data() || {};
  t.set(scoreRef, {
    allTimeScore: (scores.allTimeScore || 0) + 1,
    monthlyScore: (scores.monthlyScore || 0) + 1,
    weeklyScore: (scores.weeklyScore || 0) + 1,
  }, { merge: true });
});

// 2. Rebuild leaderboard documents (top 100 query)
// Triggered asynchronously to avoid blocking order update
```

### `rebuildLeaderboard` (Pub/Sub, triggered after score update)
```javascript
// Query top 100 visible users by score for each period
// Write sorted entries array to /leaderboard/{period} document
// Exclude users where leaderboardVisible == false
```

### `resetWeeklyScores` (Scheduled: every Monday 00:00 UTC)
```javascript
// Batch update all /userScores/{uid}.weeklyScore = 0
// Delete /leaderboard/weekly_{prev_week} document
```

### `resetMonthlyScores` (Scheduled: 1st of each month 00:00 UTC)
```javascript
// Batch update all /userScores/{uid}.monthlyScore = 0
// Delete /leaderboard/monthly_{prev_month} document
```

---

## State Management (Riverpod)

```dart
class LeaderboardNotifier extends AsyncNotifier<List<LeaderboardEntry>> {
  LeaderboardPeriod _period = LeaderboardPeriod.allTime;

  Future<void> loadLeaderboard(LeaderboardPeriod period);
  Future<LeaderboardEntry?> getCurrentUserEntry(LeaderboardPeriod period);
}
```

Firestore real-time listener on the leaderboard document keeps rankings live.

---

## Current User Rank (Outside Top 100)

If the current user is not in the top 100 entries array:
```dart
// Query /userScores/{uid} for their score
// Count documents in /userScores where score > currentUserScore and leaderboardVisible == true
// rank = count + 1
```

This is done as a separate Firestore query and displayed in the sticky bottom card.

---

## Navigation Flow

```
LeaderboardScreen
  ├── Period tabs: All-Time | Monthly | Weekly
  ├── Top 100 list (scrollable)
  │     └── Current user entry highlighted
  └── Sticky bottom card: "Your rank: #X | Score: Y orders"
```

---

## Privacy

- `leaderboardVisible` flag on `/userScores/{uid}` checked during `rebuildLeaderboard`
- Opt-out users excluded from the entries array; no gaps in ranking (re-ranked)
- User can toggle visibility in Profile → Privacy Settings

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Leaderboard document missing | Show empty state "No rankings yet" |
| Network error | Show cached leaderboard with staleness indicator |
| User not in top 100 | Show rank via separate query in sticky card |
| Score update delay | Leaderboard updates within 60s via real-time listener |
