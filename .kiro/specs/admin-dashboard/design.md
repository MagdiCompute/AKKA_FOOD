# Design Document — Admin Dashboard

## Overview

The Admin Dashboard is a Flutter module gated behind role-based access control. Admin role is stored in Firestore and verified by Cloud Functions on every privileged operation. The dashboard uses Riverpod for state and Firestore real-time listeners for live order updates.

---

## Architecture

```
Presentation Layer
  └── Screens: AdminHomeScreen, AdminMealListScreen, AdminMealFormScreen,
               AdminCategoryListScreen, AdminCategoryFormScreen,
               AdminOrderListScreen, AdminOrderDetailScreen,
               AdminAnalyticsScreen, AdminUserListScreen, AdminUserDetailScreen
  └── State: AdminMealNotifier, AdminOrderNotifier, AdminAnalyticsNotifier, AdminUserNotifier

Domain Layer
  └── Use Cases: AdminCreateMealUseCase, AdminUpdateMealUseCase, AdminDeleteMealUseCase,
                 AdminManageCategoryUseCase, AdminUpdateOrderStatusUseCase,
                 AdminGetAnalyticsUseCase, AdminManageUserUseCase

Data Layer
  └── AdminMealRepository, AdminOrderRepository, AdminAnalyticsRepository, AdminUserRepository
  └── CloudFunctionAdminDataSource (all writes go through Cloud Functions)
  └── FirestoreAdminDataSource (reads)
```

---

## Role-Based Access Control

### Firestore
```
/users/{uid}
  - role: string  // 'user' | 'admin'
```

### Flutter Route Guard (GoRouter)
```dart
redirect: (context, state) {
  final user = ref.read(authProvider);
  if (state.location.startsWith('/admin') && user?.role != 'admin') {
    return '/home';
  }
  return null;
}
```

### Cloud Functions
Every admin Cloud Function validates:
```javascript
const token = await admin.auth().verifyIdToken(idToken);
const userDoc = await db.doc(`users/${token.uid}`).get();
if (userDoc.data().role !== 'admin') throw new HttpsError('permission-denied', 'Admins only');
```

---

## Data Models

### AdminOrderView
```dart
class AdminOrderView {
  final String orderId;
  final String uid;
  final String userDisplayName;
  final String? userPhone;
  final List<OrderItem> items;
  final double total;
  final DeliveryOption deliveryOption;
  final DeliveryAddress? deliveryAddress;
  final DeliveryStatus status;
  final int? etaMinutes;
  final DateTime createdAt;
}
```

### AnalyticsSummary
```dart
class AnalyticsSummary {
  final int totalOrders;
  final double totalRevenue;
  final int activeUsers;
  final List<MealStat> topMeals;
  final List<DailyOrderCount> dailyOrders; // last 30 days
  final AnalyticsPeriod period;
}
```

---

## Firestore Structure (Admin reads)

```
/orders/{orderId}          ← Admin reads all orders (Security Rules: admin role)
/meals/{mealId}            ← Admin reads/writes via Cloud Functions
/categories/{categoryId}   ← Admin reads/writes via Cloud Functions
/users/{uid}               ← Admin reads (limited fields)
/analytics/summary         ← Pre-aggregated by Cloud Function, updated every 5 min
```

---

## Cloud Functions (Admin)

### `adminUpdateOrderStatus` (HTTPS Callable)
- Validates admin role
- Validates status transition
- Updates `/orders/{orderId}.status`
- Sets `etaMinutes` if transitioning to `out_for_delivery`
- Triggers `onOrderStatusChanged` (notification + leaderboard update)

### `adminCreateMeal` / `adminUpdateMeal` / `adminDeleteMeal`
- Validates admin role
- Writes to `/meals/{mealId}`
- Triggers Algolia sync

### `adminManageCategory`
- Validates admin role
- Writes to `/categories/{categoryId}`
- On deactivate: batch-updates all meals in category to `isAvailable=false`

### `adminManageUser`
- Validates admin role
- Updates `/users/{uid}.isDeactivated`
- On deactivate: calls `admin.auth().updateUser(uid, { disabled: true })`

### `aggregateAnalytics` (Scheduled: every 5 minutes)
```javascript
// Count orders by period, sum revenue, count active users
// Write to /analytics/summary
```

---

## State Management (Riverpod)

```dart
class AdminOrderNotifier extends AsyncNotifier<List<AdminOrderView>> {
  // Real-time listener on /orders where status not in ['delivered', 'cancelled']
  // Sorted by createdAt asc
  Future<void> updateStatus(String orderId, DeliveryStatus status, {int? etaMinutes});
}

class AdminAnalyticsNotifier extends AsyncNotifier<AnalyticsSummary> {
  // Reads /analytics/summary with real-time listener
  // Supports period switching: today | week | month
}
```

---

## Analytics Charts

Using `fl_chart` package:
- **Line chart**: daily order counts for past 30 days
- **Bar chart**: top 5 meals by order count
- **Summary cards**: total orders, revenue (XOF), active users

---

## Navigation Flow

```
AdminHomeScreen (bottom nav: Orders | Meals | Analytics | Users)
  ├── Orders tab → AdminOrderListScreen
  │     └── Order tap → AdminOrderDetailScreen
  │           └── Status update → Cloud Function call
  ├── Meals tab → AdminMealListScreen
  │     ├── Add FAB → AdminMealFormScreen
  │     └── Meal tap → AdminMealFormScreen (edit mode)
  │           └── Categories → AdminCategoryListScreen → AdminCategoryFormScreen
  ├── Analytics tab → AdminAnalyticsScreen
  └── Users tab → AdminUserListScreen
        └── User tap → AdminUserDetailScreen
```

---

## Security

- All admin writes go through Cloud Functions (never direct Firestore client writes)
- Firestore Security Rules: `/meals`, `/categories` writable only by admin role
- `/users/{uid}` readable by admin for support purposes; sensitive fields (tokens) never exposed
- Admin role assignment done manually in Firebase Console or via a separate admin provisioning script

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Non-admin accesses admin route | Redirect to home screen |
| Cloud Function permission denied | Show "Unauthorized" error snackbar |
| Order status invalid transition | Show "Invalid status change" error |
| Analytics fetch fails | Show last cached data with staleness indicator |
| Meal save fails | Keep form data, show error snackbar with retry |
