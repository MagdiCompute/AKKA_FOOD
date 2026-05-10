# Design Document — Payment Processing

## Overview

Payment is handled entirely server-side via Firebase Cloud Functions calling the Orange Money Mali API. The Flutter app never touches payment credentials. Firestore stores transaction records. Riverpod manages payment UI state.

---

## Architecture

```
Presentation Layer
  └── Screens: CheckoutScreen, PaymentProcessingScreen, OrderConfirmationScreen, PaymentFailureScreen
  └── State: PaymentNotifier (Riverpod)

Domain Layer
  └── Entities: Transaction, PaymentRequest, PaymentResult
  └── Use Cases: InitiatePaymentUseCase, PollPaymentStatusUseCase, CancelPaymentUseCase

Data Layer
  └── PaymentRepository
  └── CloudFunctionPaymentDataSource  (calls Cloud Functions)
  └── FirestoreTransactionDataSource  (reads transaction status)
```

---

## Data Models

### Transaction
```dart
class Transaction {
  final String id;              // Firestore document ID
  final String reference;       // unique non-guessable UUID
  final String uid;
  final double amount;          // XOF
  final PaymentStatus status;   // pending | processing | success | failed | cancelled | refunded
  final String? orderId;        // set on success
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum PaymentStatus { pending, processing, success, failed, cancelled, refunded }
```

### PaymentRequest
```dart
class PaymentRequest {
  final CartSummary cartSummary;
  final String phoneNumber;     // User's Orange Money number
}
```

---

## Firestore Collections

```
/transactions/{transactionId}
  - reference: string (UUID)
  - uid: string
  - amount: number (XOF)
  - status: string
  - orderId: string?
  - createdAt: timestamp
  - updatedAt: timestamp
```

---

## Cloud Functions

### `initiatePayment` (HTTPS Callable)
1. Validate caller's auth token
2. Generate unique `reference` (UUID v4)
3. Create `/transactions/{id}` with status `pending`
4. Call Orange Money Mali API: `POST /payment` with `{ amount, reference, phoneNumber, callbackUrl }`
5. Return `{ transactionId, reference }` to Flutter app

### `orangeMoneyCallback` (HTTPS Trigger — public endpoint)
1. Validate request signature (HMAC)
2. Look up transaction by `reference`
3. Check idempotency: if already `success`, return 200 immediately
4. Update transaction status
5. If `success`:
   - Call `Order_Service.createOrder(transactionId, cartSnapshot)`
   - Call `Coin_Service.creditCoins(uid, floor(amount * 0.05))`
   - Clear user's cart in Firestore
   - Send FCM push notification

---

## Payment Flow

```
CheckoutScreen
  └── User taps "Pay with Orange Money"
        └── PaymentNotifier.initiatePayment(cartSummary, phoneNumber)
              └── Cloud Function: initiatePayment()
                    └── Orange Money API sends USSD push to user's phone
              └── Flutter navigates to PaymentProcessingScreen
                    └── Firestore real-time listener on /transactions/{id}
                          ├── status == 'success' → OrderConfirmationScreen
                          ├── status == 'failed'  → PaymentFailureScreen
                          └── timeout (5 min)     → PaymentFailureScreen
```

---

## State Management (Riverpod)

```dart
enum PaymentUIState { idle, initiating, processing, success, failed, cancelled }

class PaymentNotifier extends AsyncNotifier<PaymentUIState> {
  Future<void> initiatePayment(PaymentRequest request);
  Future<void> cancelPayment(String transactionId);
  Stream<Transaction> watchTransaction(String transactionId);
}
```

Firestore real-time listener (`snapshots()`) on the transaction document drives the UI state machine.

---

## Idempotency

The `orangeMoneyCallback` Cloud Function uses a Firestore transaction to atomically check-and-set status:

```javascript
await db.runTransaction(async (t) => {
  const doc = await t.get(transactionRef);
  if (doc.data().status === 'success') return; // already processed
  t.update(transactionRef, { status: 'success', updatedAt: now });
  // trigger downstream effects
});
```

---

## Security

- Orange Money API key stored in Firebase Secret Manager, accessed only by Cloud Functions
- Callback signature validated with HMAC-SHA256 before any processing
- Flutter app only calls `initiatePayment` Cloud Function (authenticated); never calls Orange Money API directly
- All transaction writes protected by Firestore Security Rules: users can only read their own transactions

---

## Coin Credit Calculation

```dart
int calculateCoins(double totalAmount) => (totalAmount * 0.05).floor();
// e.g., 2000 XOF → 100 coins
```

Triggered by Cloud Function after confirmed payment success.

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Orange Money API timeout | Transaction stays `pending` for 5 min, then marked `failed` by scheduled Cloud Function |
| Duplicate callback | Idempotency check prevents double-processing |
| Network error during initiation | Show error, keep cart intact, allow retry |
| Payment failed | PaymentFailureScreen with reason + retry/cancel options |
| User cancels | Transaction marked `cancelled`, return to CartScreen |
