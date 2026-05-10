# Requirements Document — Payment Processing

## Introduction

The Payment Processing feature enables AKKA Food users to pay for their orders via Orange Money Mali. It handles payment initiation, status tracking, failure recovery, and post-payment order creation. It integrates with the Cart, Order_Service, and Coin_Service.

## Glossary

- **Payment_Service**: The backend service orchestrating payment requests and callbacks with Orange Money Mali.
- **Orange_Money_API**: The Orange Money Mali payment gateway API.
- **Transaction**: A single payment attempt with a unique identifier, amount, status, and timestamp.
- **Order_Service**: The service that creates an Order upon successful payment.
- **Coin_Service**: The service that credits coins after a successful payment.
- **Payment_Status**: One of: `pending`, `processing`, `success`, `failed`, `cancelled`, `refunded`.

---

## Requirements

### Requirement 1: Initiate Payment via Orange Money Mali

**User Story:** As a user, I want to pay for my order using Orange Money Mali, so that I can complete my purchase using my mobile money account.

#### Acceptance Criteria

1. WHEN an authenticated User confirms checkout with a non-zero Total, THE Payment_Service SHALL initiate a payment request to the Orange_Money_API with the Total amount in XOF, a unique transaction reference, and the User's phone number.
2. WHEN the Orange_Money_API returns a payment prompt, THE Flutter app SHALL display the Orange Money payment confirmation screen (USSD push or in-app webview) to the User.
3. WHEN the payment is initiated, THE Payment_Service SHALL create a Transaction record with status `pending` and persist it to Firestore.
4. THE Payment_Service SHALL generate a unique, non-guessable transaction reference for each payment attempt.

---

### Requirement 2: Handle Payment Success

**User Story:** As a user, I want to receive confirmation when my payment succeeds, so that I know my order has been placed.

#### Acceptance Criteria

1. WHEN the Orange_Money_API sends a success callback, THE Payment_Service SHALL update the Transaction status to `success` and emit a payment-success event.
2. WHEN a payment-success event is received, THE Order_Service SHALL create a new Order from the Cart summary and assign it a unique Order ID.
3. WHEN a payment-success event is received, THE Coin_Service SHALL credit the User with coins equal to 5% of the Total amount (rounded down to the nearest integer).
4. WHEN a payment-success event is received, THE Cart_Service SHALL clear the User's Cart.
5. WHEN payment succeeds, THE Flutter app SHALL navigate to an Order Confirmation screen displaying the Order ID, items, total paid, and estimated delivery time.
6. WHEN payment succeeds, THE Flutter app SHALL send a push notification confirming the order.

---

### Requirement 3: Handle Payment Failure

**User Story:** As a user, I want to be informed when my payment fails, so that I can retry or choose a different approach.

#### Acceptance Criteria

1. WHEN the Orange_Money_API returns a failure response or the payment times out after 5 minutes, THE Payment_Service SHALL update the Transaction status to `failed`.
2. WHEN a payment fails, THE Flutter app SHALL display an error screen with the failure reason and options to retry or cancel.
3. WHEN the User retries a failed payment, THE Payment_Service SHALL initiate a new Transaction with a new reference; THE previous failed Transaction SHALL remain in the record.
4. WHEN a payment fails, THE Cart_Service SHALL retain the Cart contents so the User does not lose their selections.

---

### Requirement 4: Handle Payment Cancellation

**User Story:** As a user, I want to cancel a pending payment, so that I can abandon the transaction without being charged.

#### Acceptance Criteria

1. WHEN an authenticated User cancels a pending payment before the Orange_Money_API confirms it, THE Payment_Service SHALL update the Transaction status to `cancelled`.
2. WHEN a payment is cancelled, THE Flutter app SHALL return the User to the Cart screen with their items intact.

---

### Requirement 5: Payment History

**User Story:** As a user, I want to view my payment history, so that I can track my past transactions.

#### Acceptance Criteria

1. WHEN an authenticated User requests their payment history, THE Payment_Service SHALL return a paginated list of Transactions ordered by timestamp descending, with a default page size of 20.
2. EACH Transaction record SHALL include: transaction reference, amount, status, timestamp, and linked Order ID (if applicable).

---

### Requirement 6: Security and Compliance

**User Story:** As a system operator, I want all payment data to be handled securely, so that user financial information is protected.

#### Acceptance Criteria

1. THE Payment_Service SHALL validate Orange_Money_API callback signatures before processing any payment status update.
2. THE Payment_Service SHALL NOT store Orange Money credentials or API secrets in the Flutter app; all API calls SHALL be made from Cloud Functions.
3. THE Payment_Service SHALL log all Transaction state changes with timestamps for audit purposes, without logging sensitive user financial data.
4. THE Payment_Service SHALL be idempotent: processing the same success callback twice SHALL NOT create duplicate Orders or credit coins twice.
