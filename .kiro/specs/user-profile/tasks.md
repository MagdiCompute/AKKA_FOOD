# Tasks — User Profile

## Task List

- [ ] 1. Domain layer — Profile entities and interfaces
  - [ ] 1.1 Create `UserProfile` entity (uid, displayName, email, phoneNumber, avatarUrl, updatedAt)
  - [ ] 1.2 Create `DeliveryAddress` entity (id, uid, label, streetAddress, city, lat, lng, isDefault, createdAt)
  - [ ] 1.3 Create `NotificationPreference` entity (uid, orderUpdates, promotions, coinEvents)
  - [ ] 1.4 Create `CoinTransaction` entity (id, uid, amount, reason, orderId, timestamp)
  - [ ] 1.5 Create `OrderSummary` entity (orderId, orderDate, items, totalAmount, status, deliveryAddress, paymentMethod)
  - [ ] 1.6 Define repository interfaces: `IProfileRepository`, `IAddressRepository`, `IOrderRepository`, `ICoinRepository`

- [ ] 2. Data layer — Firestore data sources
  - [ ] 2.1 Implement `FirestoreProfileDataSource`: read/write `/users/{uid}` document
  - [ ] 2.2 Implement `FirestoreAddressDataSource`: CRUD on `/users/{uid}/addresses` subcollection
  - [ ] 2.3 Implement `FirestoreOrderDataSource`: paginated query on `/orders` by uid
  - [ ] 2.4 Implement `FirestoreCoinDataSource`: paginated query + real-time listener on `/users/{uid}/coinTransactions`

- [ ] 3. Data layer — Avatar upload
  - [ ] 3.1 Implement `FirebaseStorageDataSource`: upload image to `/avatars/{uid}/{timestamp}.jpg`, return download URL
  - [ ] 3.2 Implement image compression using `flutter_image_compress` (max 800×800, JPEG 85%)
  - [ ] 3.3 Implement delete previous avatar from Firebase Storage on update

- [ ] 4. Data layer — Local cache
  - [ ] 4.1 Set up Hive boxes: `profile_cache`, `address_cache`, `order_history_cache`, `coin_history_cache`
  - [ ] 4.2 Implement cache read/write in each repository with 5-minute TTL
  - [ ] 4.3 Implement stale-while-revalidate pattern: serve cache, fetch fresh data in background

- [ ] 5. State management — Notifiers
  - [ ] 5.1 Implement `ProfileNotifier` (Riverpod): loadProfile, updateProfile, uploadAvatar, removeAvatar
  - [ ] 5.2 Implement `AddressNotifier`: loadAddresses, addAddress, updateAddress, deleteAddress, setDefault
  - [ ] 5.3 Implement `OrderHistoryNotifier`: paginated order history with page tracking
  - [ ] 5.4 Implement `CoinHistoryNotifier`: paginated coin history + real-time balance listener
  - [ ] 5.5 Implement `NotificationPrefsNotifier`: load and update preferences
  - [ ] 5.6 Write unit tests for all notifiers

- [ ] 6. Presentation layer — Profile screens
  - [ ] 6.1 Implement `ProfileScreen`: display name, email, phone, avatar, navigation to sub-sections
  - [ ] 6.2 Implement `EditProfileScreen`: editable fields with validation, OTP trigger for email/phone change
  - [ ] 6.3 Implement avatar picker: `image_picker` integration, compression, upload progress indicator
  - [ ] 6.4 Implement `AddressListScreen`: list with default badge, swipe-to-delete, set-default action
  - [ ] 6.5 Implement `AddressFormScreen`: label, street, city fields + optional map picker
  - [ ] 6.6 Implement `OrderHistoryScreen`: paginated list with infinite scroll
  - [ ] 6.7 Implement `OrderDetailScreen`: full order details view
  - [ ] 6.8 Implement `CoinHistoryScreen`: balance display, progress bar, paginated transaction list
  - [ ] 6.9 Implement `NotificationPrefsScreen`: toggle switches for each preference category

- [ ] 7. Account lifecycle screens
  - [ ] 7.1 Implement account deactivation flow: password confirmation dialog → Cloud Function call → sign out
  - [ ] 7.2 Implement account deletion flow: irreversible confirmation dialog → Cloud Function call → clear local data → sign out

- [ ] 8. Firestore Security Rules
  - [ ] 8.1 Write rules: `/users/{uid}/**` readable/writable only when `request.auth.uid == uid`
  - [ ] 8.2 Write rules: `/orders/{orderId}` readable when `request.auth.uid == resource.data.uid`
  - [ ] 8.3 Write Firebase Storage rules: `/avatars/{uid}/**` writable by matching uid, publicly readable

- [ ] 9. Integration testing
  - [ ] 9.1 Write integration test: view and edit profile
  - [ ] 9.2 Write integration test: add, set default, delete address
  - [ ] 9.3 Write integration test: avatar upload and removal
  - [ ] 9.4 Write integration test: offline profile display from cache
