# Design Document — User Profile

## Overview

The User Profile feature follows clean architecture (Presentation → Domain → Data). Firebase Firestore stores profile data, Firebase Storage hosts avatars, and Hive provides local caching for offline support. Riverpod manages UI state.

---

## Architecture

```
Presentation Layer
  └── Screens: ProfileScreen, EditProfileScreen, AddressListScreen, AddressFormScreen,
               OrderHistoryScreen, OrderDetailScreen, CoinHistoryScreen, NotificationPrefsScreen
  └── State: ProfileNotifier, AddressNotifier, OrderHistoryNotifier, CoinHistoryNotifier

Domain Layer
  └── Entities: UserProfile, DeliveryAddress, NotificationPreference, CoinTransaction, OrderSummary
  └── Use Cases: GetProfileUseCase, UpdateProfileUseCase, UploadAvatarUseCase,
                 ManageAddressUseCase, GetOrderHistoryUseCase, GetCoinHistoryUseCase,
                 UpdateNotificationPrefsUseCase, DeactivateAccountUseCase, DeleteAccountUseCase
  └── Repository Interfaces: IProfileRepository, IAddressRepository, IOrderRepository, ICoinRepository

Data Layer
  └── ProfileRepository, AddressRepository, OrderRepository, CoinRepository
  └── FirestoreProfileDataSource, FirebaseStorageDataSource
  └── HiveProfileCache (local cache)
```

---

## Data Models

### UserProfile
```dart
class UserProfile {
  final String uid;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime updatedAt;
}
```

### DeliveryAddress
```dart
class DeliveryAddress {
  final String id;
  final String uid;
  final String label;        // e.g., "Home", "Office"
  final String streetAddress;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
}
```

### NotificationPreference
```dart
class NotificationPreference {
  final String uid;
  final bool orderUpdates;
  final bool promotions;
  final bool coinEvents;
}
```

### CoinTransaction
```dart
class CoinTransaction {
  final String id;
  final String uid;
  final int amount;          // positive = credit, negative = debit
  final String reason;       // "Purchase reward" | "Redemption"
  final String? orderId;
  final DateTime timestamp;
}
```

### OrderSummary
```dart
class OrderSummary {
  final String orderId;
  final DateTime orderDate;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;       // "pending" | "preparing" | "delivered" | "cancelled"
  final String? deliveryAddress;
  final String paymentMethod;
}
```

---

## Firestore Collections

```
/users/{uid}
  - displayName: string
  - email: string?
  - phoneNumber: string?
  - avatarUrl: string?
  - updatedAt: timestamp

/users/{uid}/addresses/{addressId}
  - label: string
  - streetAddress: string
  - city: string
  - latitude: number?
  - longitude: number?
  - isDefault: bool
  - createdAt: timestamp

/users/{uid}/notificationPrefs
  - orderUpdates: bool (default: true)
  - promotions: bool (default: true)
  - coinEvents: bool (default: true)

/users/{uid}/coinTransactions/{txId}
  - amount: number
  - reason: string
  - orderId: string?
  - timestamp: timestamp

/orders/{orderId}   ← read-only from profile feature
  - uid: string
  - items: array
  - totalAmount: number
  - status: string
  - deliveryAddress: string?
  - paymentMethod: string
  - createdAt: timestamp
```

---

## Avatar Upload Flow

```
1. User picks image (image_picker)
2. Flutter compresses image (flutter_image_compress) → max 800×800px, JPEG quality 85
3. Validate: size ≤ 5MB, format JPEG or PNG
4. Upload to Firebase Storage: /avatars/{uid}/{timestamp}.jpg
5. Get download URL
6. Update /users/{uid}.avatarUrl in Firestore
7. Delete previous avatar file from Storage (if exists)
8. Update ProfileState with new avatarUrl
```

---

## State Management (Riverpod)

```dart
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
}

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  Future<void> loadProfile();
  Future<void> updateProfile(String displayName, String? email, String? phone);
  Future<void> uploadAvatar(File imageFile);
  Future<void> removeAvatar();
}

class AddressNotifier extends AsyncNotifier<List<DeliveryAddress>> {
  Future<void> loadAddresses();
  Future<void> addAddress(DeliveryAddress address);
  Future<void> updateAddress(DeliveryAddress address);
  Future<void> deleteAddress(String addressId);
  Future<void> setDefault(String addressId);
}
```

---

## Local Caching Strategy

Hive boxes store the last-fetched profile, address list, and first page of order/coin history:

```dart
// Hive boxes
HiveBox<UserProfile>('profile_cache')
HiveBox<List<DeliveryAddress>>('address_cache')
HiveBox<List<OrderSummary>>('order_history_cache')
HiveBox<List<CoinTransaction>>('coin_history_cache')
```

On load: return cached data immediately, then fetch from Firestore and update cache + UI. On network error: display cached data with a connectivity banner.

---

## Navigation Flow

```
ProfileScreen
  ├── Edit Profile → EditProfileScreen
  │     └── OTP verification (if email/phone changed) → back to ProfileScreen
  ├── Addresses → AddressListScreen
  │     ├── Add Address → AddressFormScreen
  │     └── Edit Address → AddressFormScreen
  ├── Order History → OrderHistoryScreen
  │     └── Order Detail → OrderDetailScreen
  ├── Coins → CoinHistoryScreen
  ├── Notifications → NotificationPrefsScreen
  ├── Deactivate Account → confirmation dialog → LoginScreen
  └── Delete Account → confirmation dialog → LoginScreen
```

---

## Address Constraints

- Maximum 10 addresses per user enforced in `AddressRepository` before writing to Firestore
- Default address: Firestore transaction atomically sets `isDefault=true` on new default and `isDefault=false` on previous default
- Deleting default address: clears `isDefault`, UI prompts user to select new default

---

## Integration Points

| Service | Integration |
|---|---|
| Auth_Service | Access_Token validated on every Firestore request via Firebase Security Rules |
| Coin_Service | `CoinRepository` reads `/users/{uid}/coinTransactions` with real-time listener |
| Order_Service | `OrderRepository` queries `/orders` where `uid == currentUser.uid` |
| Notification_Service | `NotificationPreference` changes written to Firestore; Cloud Function propagates to FCM topic subscriptions |

---

## Security

- Firestore Security Rules: `/users/{uid}/**` readable/writable only when `request.auth.uid == uid`
- Firebase Storage Rules: `/avatars/{uid}/**` writable only when `request.auth.uid == uid`; readable publicly for avatar display
- Email/phone change requires OTP re-verification before Firestore update is committed

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Network unavailable | Show cached data + connectivity banner |
| Avatar too large | Validation error before upload attempt |
| Duplicate email/phone | Firestore transaction check → user-friendly error message |
| Address limit reached | Block add action, show "Maximum 10 addresses" message |
| Account deletion fails | Show error, do not clear local data |
