# Tasks — Delivery System

## Task List

- [ ] 1. Domain layer — Delivery entities
  - [ ] 1.1 Create `Order` entity with delivery fields (deliveryOption, deliveryAddress, status, etaMinutes, deliveredAt, failureReason)
  - [ ] 1.2 Create `TrackingUpdate` entity (orderId, status, timestamp, note)
  - [ ] 1.3 Create `DeliveryStatus` enum (pending, confirmed, preparing, outForDelivery, delivered, failed)
  - [ ] 1.4 Create `DeliveryOption` enum (delivery, pickup)
  - [ ] 1.5 Define valid status transition map
  - [ ] 1.6 Define `IDeliveryRepository` interface

- [ ] 2. Firestore structure
  - [ ] 2.1 Finalize `/orders/{orderId}` schema with all delivery fields
  - [ ] 2.2 Create `/orders/{orderId}/trackingUpdates/{updateId}` subcollection schema

- [ ] 3. Cloud Functions — Delivery
  - [ ] 3.1 Implement `onOrderStatusChanged` Firestore trigger: create TrackingUpdate record, send FCM push notification (if user preference enabled), trigger leaderboard update on `delivered`
  - [ ] 3.2 Implement `adminUpdateOrderStatus` HTTPS Callable: validate admin role, validate status transition, update order, set etaMinutes if `outForDelivery`
  - [ ] 3.3 Implement push notification payloads for each status change
  - [ ] 3.4 Write unit tests for status transition validation

- [ ] 4. Data layer — DeliveryRepository
  - [ ] 4.1 Implement `FirestoreDeliveryDataSource`: real-time listener on `/orders/{orderId}`
  - [ ] 4.2 Implement TrackingUpdate subcollection reader
  - [ ] 4.3 Implement `DeliveryRepository`

- [ ] 5. State management — DeliveryTrackingNotifier
  - [ ] 5.1 Implement `DeliveryTrackingNotifier` (Riverpod): watchOrder(orderId) with Firestore snapshots stream
  - [ ] 5.2 Implement stream subscription lifecycle (cancel on dispose)
  - [ ] 5.3 Write unit tests for DeliveryTrackingNotifier

- [ ] 6. Presentation layer — Tracking screens
  - [ ] 6.1 Implement `OrderTrackingScreen`: status timeline, ETA card, real-time updates
  - [ ] 6.2 Implement `DeliveryStatusTimeline` widget: vertical timeline with stage icons, current stage highlighted
  - [ ] 6.3 Implement `ETACard` widget: shown only when status is `outForDelivery`
  - [ ] 6.4 Implement delivery confirmation message + "Rate Order" prompt on `delivered`
  - [ ] 6.5 Implement network loss indicator ("Reconnecting...") on stream error

- [ ] 7. Cart integration
  - [ ] 7.1 Implement `DeliveryOptionToggle` in CartScreen (Delivery / Pickup)
  - [ ] 7.2 Implement delivery address selector in CartScreen
  - [ ] 7.3 Display restaurant pickup address when Pickup is selected
  - [ ] 7.4 Fetch and display delivery fee from Firebase Remote Config

- [ ] 8. Admin order management
  - [ ] 8.1 Implement `AdminOrderListScreen`: active orders sorted by creation time, real-time updates
  - [ ] 8.2 Implement `AdminOrderDetailScreen`: full order details + status update controls
  - [ ] 8.3 Implement ETA input field shown when transitioning to `outForDelivery`
  - [ ] 8.4 Implement status transition validation in Admin UI (disable invalid transitions)

- [ ] 9. Push notifications
  - [ ] 9.1 Set up Firebase Cloud Messaging in Flutter app
  - [ ] 9.2 Implement deep link handling: notification tap → navigate to `OrderTrackingScreen(orderId)`
  - [ ] 9.3 Handle foreground notifications (show in-app banner)

- [ ] 10. Integration testing
  - [ ] 10.1 Write integration test: order status update → tracking screen updates within 5s
  - [ ] 10.2 Write integration test: push notification sent on status change
  - [ ] 10.3 Write integration test: admin sets ETA → displayed in tracking screen
  - [ ] 10.4 Write integration test: delivery option selection in cart
