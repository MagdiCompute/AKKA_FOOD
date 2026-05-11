# Tasks — Payment Processing

## Task List

- [x] 1. Domain layer — Payment entities
  - [x] 1.1 Create `Transaction` entity (id, reference, uid, amount, status, orderId, createdAt, updatedAt)
  - [x] 1.2 Create `PaymentRequest` DTO (cartSummary, phoneNumber)
  - [x] 1.3 Create `PaymentResult` model (transactionId, status, orderId)
  - [x] 1.4 Define `PaymentStatus` enum: pending, processing, success, failed, cancelled, refunded
  - [x] 1.5 Define `IPaymentRepository` interface

- [x] 2. Cloud Functions — Payment orchestration
  - [x] 2.1 Implement `initiatePayment` HTTPS Callable: validate auth, generate UUID reference, create `/transactions/{id}` with status `pending`, call Orange Money Mali API
  - [x] 2.2 Implement `orangeMoneyCallback` HTTPS trigger: validate HMAC signature, idempotency check, update transaction status
  - [x] 2.3 Implement post-success actions in callback: create Order, credit coins, clear cart, send FCM notification
  - [x] 2.4 Implement `expireStaleTransactions` scheduled function: mark `pending` transactions older than 5 min as `failed`
  - [x] 2.5 Store Orange Money API credentials in Firebase Secret Manager
  - [x] 2.6 Write unit tests for Cloud Functions (mock Orange Money API)

- [x] 3. Data layer — PaymentRepository
  - [x] 3.1 Implement `CloudFunctionPaymentDataSource`: call `initiatePayment` Cloud Function
  - [x] 3.2 Implement `FirestoreTransactionDataSource`: real-time listener on `/transactions/{id}`
  - [x] 3.3 Implement `PaymentRepository` composing both data sources

- [x] 4. State management — PaymentNotifier
  - [x] 4.1 Implement `PaymentNotifier` (Riverpod): initiatePayment, cancelPayment, watchTransaction
  - [x] 4.2 Implement Firestore real-time listener driving `PaymentUIState` machine
  - [x] 4.3 Implement 5-minute client-side timeout fallback
  - [x] 4.4 Write unit tests for PaymentNotifier

- [x] 5. Presentation layer — Payment screens
  - [x] 5.1 Implement `CheckoutScreen`: order summary, phone number input, "Pay with Orange Money" button
  - [x] 5.2 Implement `PaymentProcessingScreen`: animated loading indicator, status message, cancel button
  - [x] 5.3 Implement `OrderConfirmationScreen`: order ID, items, total paid, ETA, "Track Order" button
  - [x] 5.4 Implement `PaymentFailureScreen`: failure reason, "Retry" and "Cancel" buttons

- [x] 6. Order creation (Cloud Function)
  - [x] 6.1 Implement `createOrder` Cloud Function: create `/orders/{orderId}` from CartSummary snapshot stored at payment initiation
  - [x] 6.2 Implement CartSummary snapshot: save cart state to Firestore at payment initiation to prevent cart changes mid-payment

- [x] 7. Firestore Security Rules
  - [x] 7.1 Write rules: `/transactions/{id}` readable only by matching uid; writable only by Cloud Functions (service account)
  - [x] 7.2 Write rules: `/orders/{id}` readable by matching uid and admin role

- [x] 8. Integration testing
  - [x] 8.1 Write integration test: successful payment flow → order created → coins credited → cart cleared
  - [x] 8.2 Write integration test: payment failure → cart retained → retry creates new transaction
  - [x] 8.3 Write integration test: duplicate callback idempotency (no double order/coins)
  - [x] 8.4 Write integration test: payment timeout after 5 minutes
