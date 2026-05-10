# Design Document — Delivery System

## Overview

The Delivery System uses Firestore real-time listeners to push status updates to the Flutter app instantly. Cloud Functions handle status transitions and push notifications. Riverpod manages tracking UI state.

---

## Architecture

```
Presentation Layer
  └── Screens: OrderTrackingScreen, OrderConfirmationScreen
  └── Widgets: DeliveryStatusTimeline, ETACard, DeliveryOptionToggle
  └── State: DeliveryTrackingNotifier (Riverpod)

Domain Layer
  └── Entities: Order, TrackingUpdate, DeliveryStatus
  └── Use Cases: TrackOrderUseCase, GetOrderHistoryUseCase

Data Layer
  └── DeliveryRepository
  └── FirestoreDeliveryDataSource
  └── FCMNotificationService
```

---

## Data Models

### Order (delivery fields)
```dart
class Order {
  final String id;
  final String uid;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final DeliveryOption deliveryOption;  // delivery | pickup
  final DeliveryAddress? deliveryAddress;
  final DeliveryStatus status;
  final int? etaMinutes;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? failureReason;
}

enum DeliveryStatus { pending, confirmed, preparing, outForDelivery, delivered, failed }
```

### TrackingUpdate
```dart
class TrackingUpdate {
  final String orderId;
  final DeliveryStatus status;
  final DateTime timestamp;
  final String? note;
}
```

---

## Firestore Structure

```
/orders/{orderId}
  - uid: string
  - items: array
  - subtotal: number
  - deliveryFee: number
  - discount: number
  - total: number
  - deliveryOption: string ('delivery' | 'pickup')
  - deliveryAddress: map?
  - status: string
  - etaMinutes: number?
  - createdAt: timestamp
  - deliveredAt: timestamp?
  - failureReason: string?

/orders/{orderId}/trackingUpdates/{updateId}
  - status: string
  - timestamp: timestamp
  - note: string?
```

---

## Real-Time Tracking

Flutter uses Firestore `snapshots()` on `/orders/{orderId}`:

```dart
class DeliveryTrackingNotifier extends AsyncNotifier<Order> {
  StreamSubscription? _sub;

  void watchOrder(String orderId) {
    _sub = firestore.doc('orders/$orderId').snapshots().listen((snap) {
      state = AsyncData(Order.fromFirestore(snap));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

Status changes written by Admin (or Cloud Function) propagate to all listening Flutter clients within ~1 second.

---

## Status Timeline Widget

```dart
// Ordered stages displayed as a vertical timeline
const stages = [
  DeliveryStatus.pending,
  DeliveryStatus.confirmed,
  DeliveryStatus.preparing,
  DeliveryStatus.outForDelivery,
  DeliveryStatus.delivered,
];

// Each stage: icon + label + timestamp (from trackingUpdates subcollection)
// Current stage: highlighted; past stages: filled; future stages: greyed
```

---

## Cloud Functions

### `onOrderStatusChanged` (Firestore trigger on `/orders/{id}.status`)
```javascript
// 1. Create TrackingUpdate record
// 2. Send FCM push notification to user (if notifications enabled)
// 3. If status == 'delivered': update Leaderboard score, trigger coin credit
// 4. If status == 'failed': flag for admin follow-up
```

### Push Notification Payloads
```javascript
// out_for_delivery
{ title: "Your order is on the way!", body: `ETA: ${etaMinutes} minutes`, data: { orderId } }

// delivered
{ title: "Order delivered!", body: "Tap to rate your experience", data: { orderId } }

// failed
{ title: "Delivery issue", body: "We couldn't deliver your order. We'll contact you shortly.", data: { orderId } }
```

---

## Delivery Fee (Remote Config)

```dart
// Fetched on app start, cached locally
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();
final deliveryFee = remoteConfig.getDouble('delivery_fee_xof'); // default: 500.0
```

---

## Admin Status Update Flow

Admin Dashboard calls a Cloud Function `updateOrderStatus(orderId, newStatus, etaMinutes?)`:
1. Validates status transition is legal (e.g., can't go from `delivered` back to `preparing`)
2. Updates `/orders/{orderId}.status`
3. Cloud Function trigger fires → notification + tracking update

Valid transitions:
```
pending → confirmed → preparing → out_for_delivery → delivered
                                                    → failed
```

---

## Navigation Flow

```
OrderConfirmationScreen
  └── "Track Order" button → OrderTrackingScreen(orderId)

OrderTrackingScreen
  ├── Real-time status timeline
  ├── ETA card (when out_for_delivery)
  └── "Rate Order" button (when delivered) → RatingScreen
```

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Network loss during tracking | Show last known status + "Reconnecting..." indicator |
| Order not found | Show "Order not found" error with support contact |
| Delivery failed | Show failure reason + "Contact support" button |
| ETA not set | Hide ETA card until admin sets it |
