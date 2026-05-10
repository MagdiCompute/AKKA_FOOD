# Tasks — Coins

## Task List

- [ ] 1. Domain layer — Coin entities
  - [ ] 1.1 Create `CoinTransaction` entity (id, uid, amount, reason, orderId, timestamp)
  - [ ] 1.2 Create `CoinBalance` value object (total, nextThreshold, coinsToNext)
  - [ ] 1.3 Define `ICoinRepository` interface

- [ ] 2. Cloud Functions — Coin logic
  - [ ] 2.1 Implement `onPaymentSuccess` Firestore trigger: compute `floor(amount * 0.05)` coins, idempotency check by orderId, atomic Firestore transaction to credit balance + create CoinTransaction
  - [ ] 2.2 Implement `redeemCoins` HTTPS Callable: validate balance ≥ redeemedCoins, validate multiple of 1000, atomic debit + CoinTransaction creation
  - [ ] 2.3 Implement idempotency: check for existing CoinTransaction with same orderId before crediting
  - [ ] 2.4 Write unit tests for coin calculation and redemption logic

- [ ] 3. Data layer — CoinRepository
  - [ ] 3.1 Implement `FirestoreCoinDataSource`: real-time listener on `/users/{uid}.coinBalance`
  - [ ] 3.2 Implement paginated query on `/users/{uid}/coinTransactions` ordered by timestamp desc
  - [ ] 3.3 Implement `CoinRepository` composing Firestore data source

- [ ] 4. State management — CoinNotifier
  - [ ] 4.1 Implement `CoinNotifier` (Riverpod): real-time balance stream, paginated history
  - [ ] 4.2 Implement `CoinBalance` computation (total, nextThreshold, coinsToNext)
  - [ ] 4.3 Write unit tests for CoinNotifier

- [ ] 5. Presentation layer — Coin widgets and screens
  - [ ] 5.1 Implement `CoinBalanceWidget`: coin icon + balance number, displayed in app header/profile
  - [ ] 5.2 Implement `CoinProgressBar`: progress toward next 1000-coin threshold with label "X coins to next reward"
  - [ ] 5.3 Implement `CoinHistoryScreen`: balance card, progress bar, paginated transaction list
  - [ ] 5.4 Implement `CoinTransactionTile`: +/− amount, reason, date, linked order ID
  - [ ] 5.5 Implement coin earned notification (in-app snackbar after payment success)

- [ ] 6. Cart integration
  - [ ] 6.1 Integrate `CoinNotifier` into `CartScreen`: show redemption option when balance ≥ 1000
  - [ ] 6.2 Implement `CoinRedemptionCard` in CartScreen: display redeemable amount, toggle apply/remove
  - [ ] 6.3 Pass redeemed coins in `CartSummary` to Payment screen

- [ ] 7. Firestore Security Rules
  - [ ] 7.1 Write rules: `/users/{uid}/coinTransactions` readable by matching uid; writable only by Cloud Functions
  - [ ] 7.2 Write rules: `/users/{uid}.coinBalance` readable by matching uid; writable only by Cloud Functions

- [ ] 8. Integration testing
  - [ ] 8.1 Write integration test: complete order → coins credited at 5% of total
  - [ ] 8.2 Write integration test: redeem 1000 coins → balance decremented → discount applied
  - [ ] 8.3 Write integration test: duplicate payment callback → no double coin credit
  - [ ] 8.4 Write integration test: balance updates in real time after payment
