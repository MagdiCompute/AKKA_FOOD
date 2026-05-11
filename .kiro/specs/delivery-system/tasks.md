# Tasks — Delivery System

## Task List

- [x] 1. Domain layer — Delivery entities
  - [x] 1.1 Create `Order` entity with delivery fields (deliveryOption, deliveryAddress, status, etaMinutes, deliveredAt, failureReason)
  - [x] 1.2 Create `TrackingUpdate` entity (orderId, status, timestamp, note)
  - [x] 1.3 Create `DeliveryStatus` enum (pending, confirmed, preparing, outForDelivery, delivered, failed)
  - [x] 1.4 Create `DeliveryOption` enum (delivery, pickup)
  - [x] 1.5 Define valid status transition map
  - [x] 1.6 Define `IDeliveryRepository` interface

- [x] 2. Firestore structure
  - [x] 2.1 Finalize `/orders/{orderId}` schema with all delivery fields
  - [x] 2.2 Create `/orders/{orderId}/trackingUpdates/{updateId}` subcollection schema

- [x] 3. Cloud Functions — Delivery
  - [x] 3.1 Implement `onOrderStatusChanged` Firestore trigger: create TrackingUpdate record, send FCM push notification (if user preference enabled), trigger leaderboard update on `delivered`
  - [x] 3.2 Implement `adminUpdateOrderStatus` HTTPS Callable: validate admin role, validate status transition, update order, set etaMinutes if `outForDelivery`
  - [x] 3.3 Implement push notification payloads for each status change
  - [x] 3.4 Write unit tests for status transition validation

- [x] 4. Data layer — DeliveryRepository
  - [x] 4.1 Implement `FirestoreDeliveryDataSource`: real-time listener on `/orders/{orderId}`
  - [x] 4.2 Implement TrackingUpdate subcollection reader
  - [x] 4.3 Implement `DeliveryRepository`

- [x] 5. State management — DeliveryTrackingNotifier
  - [x] 5.1 Implement `DeliveryTrackingNotifier` (Riverpod): watchOrder(orderId) with Firestore snapshots stream
  - [x] 5.2 Implement stream subscription lifecycle (cancel on dispose)
  - [x] 5.3 Write unit tests for DeliveryTrackingNotifier

- [x] 6. Presentation layer — Tracking screens
  - [x] 6.1 Implement `OrderTrackingScreen`: status timeline, ETA card, real-time updates
  - [x] 6.2 Implement `DeliveryStatusTimeline` widget: vertical timeline with stage icons, current stage highlighted
  - [x] 6.3 Implement `ETACard` widget: shown only when status is `outForDelivery`
  - [x] 6.4 Implement delivery confirmation message + "Rate Order" prompt on `delivered`
  - [x] 6.5 Implement network loss indicator ("Reconnecting...") on stream error

- [x] 7. Cart integration
  - [x] 7.1 Implement `DeliveryOptionToggle` in CartScreen (Delivery / Pickup)
  - [x] 7.2 Implement delivery address selector in CartScreen
  - [x] 7.3 Display restaurant pickup address when Pickup is selected
  - [x] 7.4 Fetch and display delivery fee from Firebase Remote Config

- [x] 8. Admin order management
  - [x] 8.1 Implement `AdminOrderListScreen`: active orders sorted by creation time, real-time updates
  - [x] 8.2 Implement `AdminOrderDetailScreen`: full order details + status update controls
  - [x] 8.3 Implement ETA input field shown when transitioning to `outForDelivery`
  - [x] 8.4 Implement status transition validation in Admin UI (disable invalid transitions)

- [x] 9. Push notifications
  - [x] 9.1 Set up Firebase Cloud Messaging in Flutter app
  - [x] 9.2 Implement deep link handling: notification tap → navigate to `OrderTrackingScreen(orderId)`
  - [x] 9.3 Handle foreground notifications (show in-app banner)

- [x] 10. Integration testing
  - [x] 10.1 Write integration test: order status update → tracking screen updates within 5s
  - [x] 10.2 Write integration test: push notification sent on status change
  - [x] 10.3 Write integration test: admin sets ETA → displayed in tracking screen
  - [x] 10.4 Write integration test: delivery option selection in cart
