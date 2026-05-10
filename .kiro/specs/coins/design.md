# Design Document — Coins

## Overview

The Coins system is event-driven. Cloud Functions listen for payment-success events and credit coins atomically. Firestore stores coin transactions as the source of truth; the balance is a computed aggregate. Riverpod provides reactive UI updates.

---

## Architecture

```
Presentation Layer
  └── Widgets: CoinBalanceWidget (app header), CoinProgressBar, CoinHistoryScreen
  └── State: CoinNotifier (Riverpod)

Domain Layer
  └── Entities: CoinBalance, CoinTransaction
  └── Use Cases: GetCoinBalanceUseCase, GetCoinHistoryUseCase, RedeemCoinsUseCase

Data Layer
  └── CoinRepository
  └── FirestoreCoinDataSource
```

---

## Data Models

### CoinTransaction
```dart
class CoinTransaction {
  final String id;
  final String uid;
  final int amount;        // positive = credit, negative = debit
  final String reason;     // "Purchase reward" | "Redemption"
  final String? orderId;
  final DateTime timestamp;
}
```

### CoinBalance (computed)
```dart
class CoinBalance {
  final int total;
  final int nextThreshold;   // next multiple of 1000 above total
  final int coinsToNext;     // nextThreshold - total
}
```

---

## Firestore Structure

```
/users/{uid}/coinTransactions/{txId}
  - amount: number
  - reason: string
  - orderId: string?
  - timestamp: timestamp

/users/{uid}
  - coinBalance: number   ← denormalized for fast reads, kept in sync via Cloud Function
```

The `coinBalance` field on the user document is a denormalized cache updated atomically alongside each transaction write. It is never written directly by the client.

---

## Cloud Functions

### `onPaymentSuccess` (Firestore trigger on `/transactions/{id}` status → 'success')
```javascript
const coins = Math.floor(amount * 0.05);
if (coins === 0) return; // no coins for zero-cash orders

await db.runTransaction(async (t) => {
  const userRef = db.doc(`users/${uid}`);
  const user = await t.get(userRef);
  const currentBalance = user.data().coinBalance || 0;

  const txRef = db.collection(`users/${uid}/coinTransactions`).doc();
  t.set(txRef, { amount: coins, reason: 'Purchase reward', orderId, timestamp: now });
  t.update(userRef, { coinBalance: currentBalance + coins });
});
```

Idempotency: Cloud Function checks if a coin transaction with the same `orderId` already exists before crediting.

### `onCoinRedemption` (called from Cart checkout Cloud Function)
```javascript
await db.runTransaction(async (t) => {
  const userRef = db.doc(`users/${uid}`);
  const user = await t.get(userRef);
  const balance = user.data().coinBalance;

  if (balance < redeemedCoins) throw new Error('Insufficient coins');
  if (redeemedCoins % 1000 !== 0) throw new Error('Must redeem in multiples of 1000');

  const txRef = db.collection(`users/${uid}/coinTransactions`).doc();
  t.set(txRef, { amount: -redeemedCoins, reason: 'Redemption', orderId, timestamp: now });
  t.update(userRef, { coinBalance: balance - redeemedCoins });
});
```

---

## State Management (Riverpod)

```dart
class CoinNotifier extends AsyncNotifier<CoinBalance> {
  // Real-time listener on /users/{uid}.coinBalance
  Stream<int> watchBalance(String uid);
  Future<List<CoinTransaction>> getHistory({int page = 0});
}
```

`watchBalance` uses Firestore `snapshots()` for real-time updates — balance updates within seconds of a payment.

---

## Coin Progress Bar

```dart
// Displayed in profile and cart
int coinsToNext = 1000 - (balance % 1000);
double progress = (balance % 1000) / 1000.0;
// "You need X more coins to redeem 1000 XOF"
```

---

## Redemption Validation (client-side pre-check)

```dart
bool canRedeem(int balance) => balance >= 1000;
int maxRedeemable(int balance, double subtotal) {
  final byBalance = (balance ~/ 1000) * 1000;
  final bySubtotal = subtotal.floor();
  return min(byBalance, bySubtotal ~/ 1000 * 1000);
}
```

Server-side Cloud Function performs the authoritative check.

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Duplicate coin credit | Idempotency check by orderId prevents double credit |
| Insufficient coins at redemption | Cloud Function returns error; Flutter shows "Insufficient coins" |
| Non-multiple-of-1000 redemption | Blocked client-side and server-side |
| Race condition on balance | Firestore transaction ensures atomic read-modify-write |
