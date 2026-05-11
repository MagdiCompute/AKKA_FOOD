# Tasks — Cart

## Task List

- [x] 1. Domain layer — Cart entities
  - [x] 1.1 Create `CartItem` entity (mealId, mealName, mealImageUrl, unitPrice, quantity, isAvailable)
  - [x] 1.2 Create `Cart` entity with computed properties: subtotal, deliveryFee, discount, total, itemCount
  - [x] 1.3 Create `CartSummary` DTO for handoff to Payment screen
  - [x] 1.4 Create `CartValidationResult` model
  - [x] 1.5 Define `ICartRepository` interface

- [ ] 2. Data layer — Hive persistence
  - [ ] 2.1 Set up Hive box `cart` with JSON serialization for Cart
  - [ ] 2.2 Implement `HiveCartDataSource`: save, load, clear
  - [ ] 2.3 Implement `CartRepository` composing HiveCartDataSource and MealRepository (for availability re-check)

- [ ] 3. State management — CartNotifier
  - [ ] 3.1 Implement `CartNotifier` (Riverpod `Notifier<Cart>`): addItem, removeItem, updateQuantity, clearCart
  - [ ] 3.2 Implement `setDeliveryOption` and `setDeliveryAddress`
  - [ ] 3.3 Implement `applyCoins` and `removeCoins` with max-redeemable calculation
  - [ ] 3.4 Implement `validateForCheckout`: empty check, availability re-check, address check
  - [ ] 3.5 Implement Hive auto-save listener on every state change
  - [ ] 3.6 Implement cart restore on app launch from Hive
  - [ ] 3.7 Write unit tests for CartNotifier (add, remove, quantity, coin redemption, validation)

- [ ] 4. Presentation layer — Cart screens
  - [ ] 4.1 Implement `CartScreen`: CartItem list, summary card, delivery toggle, coin redemption card, checkout button
  - [ ] 4.2 Implement `CartItemTile`: image, name, price, quantity stepper (+/−), swipe-to-delete
  - [ ] 4.3 Implement `CartSummaryCard`: subtotal, delivery fee, discount, total breakdown
  - [ ] 4.4 Implement `DeliveryToggle`: Delivery / Pickup segmented control
  - [ ] 4.5 Implement address selector: navigate to AddressListScreen, return selected address
  - [ ] 4.6 Implement `CoinRedemptionCard`: show only when balance ≥ 1000, display redeemable amount
  - [ ] 4.7 Implement empty cart state with "Browse Menu" button
  - [ ] 4.8 Implement cart badge (item count) on bottom navigation bar icon
  - [ ] 4.9 Implement clear-cart confirmation dialog

- [ ] 5. Checkout validation UI
  - [ ] 5.1 Highlight unavailable CartItems in red with "Remove" prompt
  - [ ] 5.2 Show inline error when delivery selected but no address
  - [ ] 5.3 Block checkout button when validation fails

- [ ] 6. Remote Config — Delivery fee
  - [ ] 6.1 Set up Firebase Remote Config with `delivery_fee_xof` parameter (default: 500)
  - [ ] 6.2 Fetch Remote Config on app start and cache locally

- [ ] 7. Integration testing
  - [ ] 7.1 Write integration test: add meal → view cart → update quantity → remove item
  - [ ] 7.2 Write integration test: coin redemption applied and removed
  - [ ] 7.3 Write integration test: cart persists across app restart
  - [ ] 7.4 Write integration test: checkout blocked when unavailable item present
