# Requirements Document — Coins

## Introduction

The Coins feature is AKKA Food's loyalty reward system. Users earn coins on every purchase (5% of total cost) and can redeem coins for meal discounts (1000 coins = 1000 XOF discount). This feature integrates with Payment Processing, Cart, and the Leaderboard.

## Glossary

- **Coin_Service**: The backend service managing coin balances, transactions, and redemptions.
- **Coin_Balance**: The current number of coins held by a User.
- **Coin_Transaction**: A record of a coin credit or debit event.
- **Redemption**: The act of converting coins into a discount applied to a Cart.
- **Earning_Rate**: 5% of the order total, rounded down to the nearest integer coin.
- **Redemption_Rate**: 1000 coins = 1000 XOF discount (1:1 ratio in multiples of 1000).

---

## Requirements

### Requirement 1: Earn Coins on Purchase

**User Story:** As a user, I want to earn coins every time I complete a purchase, so that I am rewarded for my loyalty.

#### Acceptance Criteria

1. WHEN a payment is confirmed as successful, THE Coin_Service SHALL credit the User's Coin_Balance with coins equal to `floor(totalAmount * 0.05)`.
2. THE Coin_Service SHALL create a Coin_Transaction record with: amount (positive), reason "Purchase reward", linked order ID, and timestamp.
3. THE Coin_Service SHALL credit coins only once per successful payment; duplicate payment callbacks SHALL NOT result in duplicate coin credits.
4. WHEN coins are credited, THE Flutter app SHALL display a notification informing the User of the coins earned.
5. THE Coin_Service SHALL NOT credit coins for orders paid entirely with coin redemptions (zero cash payment).

---

### Requirement 2: Redeem Coins

**User Story:** As a user with at least 1000 coins, I want to redeem my coins for a discount on my order, so that I can use my rewards.

#### Acceptance Criteria

1. WHEN an authenticated User redeems coins in the Cart, THE Coin_Service SHALL verify the User's Coin_Balance is at least 1000 before allowing redemption.
2. THE Coin_Service SHALL only allow redemption in multiples of 1000 coins.
3. WHEN coins are redeemed, THE Coin_Service SHALL debit the redeemed amount from the User's Coin_Balance and create a Coin_Transaction with reason "Redemption" and the linked order ID.
4. THE Coin_Service SHALL debit coins only after the order is confirmed (payment success); IF the payment fails, THE Coin_Service SHALL NOT debit any coins.
5. WHEN coins are redeemed, THE Coin_Service SHALL ensure the Coin_Balance never goes below 0.

---

### Requirement 3: View Coin Balance

**User Story:** As a user, I want to see my current coin balance prominently in the app, so that I always know how many coins I have.

#### Acceptance Criteria

1. WHEN an authenticated User opens the app, THE Coin_Service SHALL display the User's current Coin_Balance in the app header or profile section.
2. WHEN the Coin_Balance changes, THE Flutter app SHALL update the displayed balance within 5 seconds without requiring a manual refresh.
3. THE Flutter app SHALL display a progress indicator showing how many more coins are needed to reach the next 1000-coin redemption threshold.

---

### Requirement 4: Coin Transaction History

**User Story:** As a user, I want to view a history of my coin earnings and redemptions, so that I can track my rewards activity.

#### Acceptance Criteria

1. WHEN an authenticated User requests their coin history, THE Coin_Service SHALL return a paginated list of Coin_Transactions ordered by timestamp descending, page size 20.
2. EACH Coin_Transaction SHALL display: amount (+ for credit, − for debit), reason, linked order ID (if applicable), and timestamp.
3. WHEN the User has no transactions, THE Flutter app SHALL display an empty-state message.

---

### Requirement 5: Coin Balance Integrity

**User Story:** As a system operator, I want coin balances to be accurate and tamper-proof, so that the reward system is fair.

#### Acceptance Criteria

1. THE Coin_Service SHALL compute the Coin_Balance as the sum of all Coin_Transactions for a User; the balance SHALL never be stored as a mutable field that can be set directly without a transaction record.
2. THE Coin_Service SHALL use Firestore transactions to atomically update the Coin_Balance and create the Coin_Transaction record, preventing race conditions.
3. WHEN an account is deleted, THE Coin_Service SHALL permanently delete all Coin_Transactions and the Coin_Balance for that User.
