# Requirements Document — Leaderboard

## Introduction

The Leaderboard feature gamifies AKKA Food by ranking users from the most active buyer to the least, based on total orders placed. It encourages repeat purchases and creates a sense of community competition.

## Glossary

- **Leaderboard_Service**: The backend service computing and serving leaderboard rankings.
- **Rank**: A User's position on the leaderboard, with 1 being the highest.
- **Score**: The metric used for ranking — total number of completed orders placed by a User.
- **LeaderboardEntry**: A single row on the leaderboard containing rank, display name, avatar, and score.
- **Period**: The time window for ranking — all-time, monthly, or weekly.

---

## Requirements

### Requirement 1: Display Leaderboard

**User Story:** As a user, I want to see a leaderboard ranking users by number of orders, so that I can see how I compare to other customers.

#### Acceptance Criteria

1. WHEN an authenticated User opens the Leaderboard screen, THE Leaderboard_Service SHALL return the top 100 LeaderboardEntries ranked by Score descending for the selected Period.
2. EACH LeaderboardEntry SHALL display: rank, display name, avatar (or placeholder), and score (total orders).
3. THE Leaderboard screen SHALL support three Period tabs: All-Time, Monthly, and Weekly.
4. WHEN the User switches Period tabs, THE Leaderboard_Service SHALL return the rankings for the selected Period within 3 seconds.
5. THE Leaderboard_Service SHALL update rankings within 60 seconds of a new completed order.

---

### Requirement 2: Highlight Current User's Position

**User Story:** As a user, I want to see my own rank highlighted on the leaderboard, so that I can quickly find my position.

#### Acceptance Criteria

1. WHEN an authenticated User views the Leaderboard, THE Flutter app SHALL visually highlight the current User's LeaderboardEntry with a distinct color or indicator.
2. IF the current User's rank is outside the top 100, THE Flutter app SHALL display the User's rank, score, and a separator below the top 100 list.
3. THE Flutter app SHALL display the current User's rank and score in a sticky card at the bottom of the Leaderboard screen regardless of scroll position.

---

### Requirement 3: Leaderboard Score Calculation

**User Story:** As a system operator, I want leaderboard scores to reflect completed orders accurately, so that rankings are fair.

#### Acceptance Criteria

1. THE Leaderboard_Service SHALL count only orders with status `delivered` or `completed` toward a User's Score.
2. THE Leaderboard_Service SHALL NOT count cancelled or refunded orders toward a User's Score.
3. WHEN a User's order status changes to `delivered`, THE Leaderboard_Service SHALL update the User's Score within 60 seconds.
4. FOR the Monthly Period, THE Leaderboard_Service SHALL count only orders completed within the current calendar month.
5. FOR the Weekly Period, THE Leaderboard_Service SHALL count only orders completed within the current calendar week (Monday to Sunday).

---

### Requirement 4: Privacy

**User Story:** As a user, I want control over whether my profile appears on the leaderboard, so that I can protect my privacy.

#### Acceptance Criteria

1. THE Profile_Service SHALL provide a leaderboard visibility toggle in notification/privacy preferences, defaulting to visible (opted in).
2. WHEN a User opts out of the leaderboard, THE Leaderboard_Service SHALL exclude that User's entry from all leaderboard responses.
3. WHEN a User opts out, their rank position SHALL be removed and remaining entries SHALL be re-ranked without gaps.
