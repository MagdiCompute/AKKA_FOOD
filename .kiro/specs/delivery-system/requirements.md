# Requirements Document — Delivery System

## Introduction

The Delivery System manages the lifecycle of food delivery for AKKA Food orders. It covers delivery option selection, address assignment, real-time order tracking, delivery status updates, and estimated delivery time. It integrates with the Cart, Order_Service, and Admin Dashboard.

## Glossary

- **Delivery_Service**: The backend service managing delivery assignments, status updates, and tracking.
- **Order**: A confirmed purchase created after successful payment.
- **Delivery_Status**: One of: `pending`, `confirmed`, `preparing`, `out_for_delivery`, `delivered`, `failed`.
- **ETA**: Estimated time of arrival for a delivery.
- **Delivery_Agent**: A person responsible for physically delivering the order (managed by admin).
- **Tracking_Update**: A timestamped status change event for an Order.

---

## Requirements

### Requirement 1: Delivery Option Selection

**User Story:** As a user, I want to choose between delivery and pickup when placing an order, so that I can decide how I receive my food.

#### Acceptance Criteria

1. THE Cart screen SHALL allow the User to select either "Delivery" or "Pickup" before checkout.
2. WHEN "Delivery" is selected, THE Cart screen SHALL require the User to confirm or select a delivery address before proceeding to payment.
3. WHEN "Pickup" is selected, THE Cart screen SHALL not require a delivery address and SHALL display the restaurant's pickup address.
4. THE Delivery_Service SHALL record the selected delivery option on the Order upon creation.

---

### Requirement 2: Real-Time Order Tracking

**User Story:** As a user who chose delivery, I want to track my order in real time, so that I know when to expect my food.

#### Acceptance Criteria

1. WHEN an authenticated User opens the Order Tracking screen for a delivery order, THE Delivery_Service SHALL display the current Delivery_Status.
2. WHEN the Delivery_Status changes, THE Flutter app SHALL update the tracking screen within 5 seconds without requiring a manual refresh.
3. THE Order Tracking screen SHALL display a visual timeline of all Delivery_Status stages, highlighting the current stage.
4. THE Order Tracking screen SHALL display the ETA when the order status is `out_for_delivery`.
5. WHEN the order status reaches `delivered`, THE Flutter app SHALL display a delivery confirmation message and prompt the User to rate the order.

---

### Requirement 3: Delivery Status Notifications

**User Story:** As a user, I want to receive push notifications when my order status changes, so that I stay informed without keeping the app open.

#### Acceptance Criteria

1. WHEN an Order's Delivery_Status changes, THE Delivery_Service SHALL send a push notification to the User (if order update notifications are enabled in their preferences).
2. THE push notification SHALL include the new status and a deep link to the Order Tracking screen.
3. WHEN the order is `out_for_delivery`, THE Delivery_Service SHALL send a notification with the ETA.
4. WHEN the order is `delivered`, THE Delivery_Service SHALL send a delivery confirmation notification.

---

### Requirement 4: Admin — Manage Delivery Status

**User Story:** As an admin, I want to update the delivery status of orders, so that customers receive accurate tracking information.

#### Acceptance Criteria

1. WHEN an Admin updates an Order's Delivery_Status, THE Delivery_Service SHALL persist the new status and create a Tracking_Update record with the timestamp.
2. THE Admin Dashboard SHALL display all active delivery orders with their current status, sorted by order time ascending.
3. WHEN an Admin marks an order as `delivered`, THE Delivery_Service SHALL record the actual delivery timestamp.
4. WHEN an Admin marks an order as `failed`, THE Delivery_Service SHALL notify the User and flag the order for follow-up.
5. THE Admin SHALL be able to set an ETA (in minutes) when marking an order as `out_for_delivery`.

---

### Requirement 5: Delivery Fee

**User Story:** As a user, I want to know the delivery fee before confirming my order, so that I can make an informed decision.

#### Acceptance Criteria

1. THE Cart screen SHALL display the Delivery_Fee clearly before the User proceeds to payment.
2. THE Delivery_Fee SHALL be fetched from a remote configuration (Firebase Remote Config) so it can be updated without an app release.
3. WHEN the User selects "Pickup", THE Cart screen SHALL display a Delivery_Fee of 0 XOF.

---

### Requirement 6: Order History with Delivery Details

**User Story:** As a user, I want to see delivery details in my order history, so that I can review past deliveries.

#### Acceptance Criteria

1. WHEN an authenticated User views a past order in their order history, THE Order_Service SHALL include the delivery option, delivery address (if applicable), final Delivery_Status, and actual delivery timestamp.
2. WHEN a past order had delivery status `failed`, THE Order_Service SHALL display the failure reason in the order detail.
