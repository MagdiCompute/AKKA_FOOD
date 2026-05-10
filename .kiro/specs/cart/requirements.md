# Requirements Document — Cart

## Introduction

The Cart feature allows authenticated users of AKKA Food to collect meals they intend to purchase, adjust quantities, apply coin redemptions, choose delivery or pickup, and proceed to checkout. It is the bridge between the Meal Catalog and the Payment Processing feature.

## Glossary

- **Cart**: A temporary container holding one or more CartItems selected by the User before checkout.
- **CartItem**: A single entry in the Cart representing a Meal with a chosen quantity.
- **Cart_Service**: The backend/local service managing Cart state.
- **Coin_Service**: The service managing coin balances and redemptions.
- **Order_Service**: The service that receives the finalized Cart and creates an Order.
- **Subtotal**: The sum of (price × quantity) for all CartItems.
- **Delivery_Fee**: An additional charge applied when the User selects delivery.
- **Discount**: A reduction applied to the Subtotal via coin redemption.
- **Total**: Subtotal + Delivery_Fee − Discount.

---

## Requirements

### Requirement 1: Add Meal to Cart

**User Story:** As a signed-in user, I want to add a meal to my cart, so that I can collect items before placing an order.

#### Acceptance Criteria

1. WHEN an authenticated User taps "Add to Cart" on a Meal Detail screen for an available meal, THE Cart_Service SHALL add the meal to the Cart with a quantity of 1.
2. WHEN an authenticated User adds a meal that is already in the Cart, THE Cart_Service SHALL increment the existing CartItem quantity by 1 instead of creating a duplicate entry.
3. WHEN an authenticated User attempts to add a meal with Availability set to false, THE Cart_Service SHALL reject the action and display an "Item unavailable" error.
4. THE Cart_Service SHALL persist the Cart locally so that it survives app restarts.
5. WHEN a meal is added to the Cart, THE Flutter app SHALL display a visual confirmation (e.g., badge update on cart icon, snackbar).

---

### Requirement 2: View Cart

**User Story:** As a signed-in user, I want to view the contents of my cart, so that I can review my selections before checkout.

#### Acceptance Criteria

1. WHEN an authenticated User opens the Cart screen, THE Cart_Service SHALL display all CartItems with each item's name, image, unit price, quantity, and line total (price × quantity).
2. THE Cart_Service SHALL display the Subtotal, Delivery_Fee (if delivery is selected), Discount (if coins are redeemed), and Total.
3. WHEN the Cart is empty, THE Flutter app SHALL display an empty-state message and a button to navigate to the Meal Catalog.
4. THE Cart screen SHALL display the total number of items (sum of all quantities) as a badge on the cart icon throughout the app.

---

### Requirement 3: Update Item Quantity

**User Story:** As a signed-in user, I want to increase or decrease the quantity of a meal in my cart, so that I can adjust my order before checkout.

#### Acceptance Criteria

1. WHEN an authenticated User increases a CartItem quantity, THE Cart_Service SHALL increment the quantity by 1 and recalculate the Subtotal and Total.
2. WHEN an authenticated User decreases a CartItem quantity to 1 and taps decrease again, THE Cart_Service SHALL remove the CartItem from the Cart.
3. WHEN an authenticated User sets a CartItem quantity to 0 via direct input, THE Cart_Service SHALL remove the CartItem from the Cart.
4. THE Cart_Service SHALL enforce a maximum quantity of 20 per CartItem; WHEN the User attempts to exceed 20, THE Cart_Service SHALL cap the quantity at 20 and display a maximum-quantity warning.

---

### Requirement 4: Remove Item from Cart

**User Story:** As a signed-in user, I want to remove a meal from my cart, so that I can correct my selection before checkout.

#### Acceptance Criteria

1. WHEN an authenticated User removes a CartItem, THE Cart_Service SHALL delete the CartItem from the Cart and recalculate the Subtotal and Total.
2. WHEN the last CartItem is removed, THE Cart_Service SHALL display the empty-cart state.
3. THE Flutter app SHALL require a swipe-to-delete or explicit remove button action to prevent accidental removal.

---

### Requirement 5: Clear Cart

**User Story:** As a signed-in user, I want to clear my entire cart, so that I can start a fresh selection.

#### Acceptance Criteria

1. WHEN an authenticated User confirms a clear-cart action, THE Cart_Service SHALL remove all CartItems from the Cart.
2. THE Flutter app SHALL display a confirmation dialog before clearing the Cart.

---

### Requirement 6: Delivery or Pickup Selection

**User Story:** As a signed-in user, I want to choose between delivery and pickup, so that I can decide how I receive my order.

#### Acceptance Criteria

1. THE Cart screen SHALL display a toggle allowing the User to select either "Delivery" or "Pickup".
2. WHEN the User selects "Delivery", THE Cart_Service SHALL apply the Delivery_Fee to the Total and prompt the User to select or confirm a delivery address.
3. WHEN the User selects "Pickup", THE Cart_Service SHALL set the Delivery_Fee to 0 and remove the delivery address requirement.
4. THE default selection SHALL be "Delivery" if the User has a Default_Address; otherwise "Pickup".

---

### Requirement 7: Coin Redemption in Cart

**User Story:** As a signed-in user with at least 1000 coins, I want to redeem my coins for a discount on my order, so that I can benefit from my loyalty rewards.

#### Acceptance Criteria

1. WHEN an authenticated User's Coin_Balance is at least 1000, THE Cart screen SHALL display a coin redemption option.
2. WHEN the User activates coin redemption, THE Coin_Service SHALL calculate the maximum redeemable coins as the largest multiple of 1000 that does not exceed the User's Coin_Balance and does not exceed the Subtotal in XOF.
3. WHEN coin redemption is applied, THE Cart_Service SHALL set the Discount equal to the redeemed coin amount (1 coin = 1 XOF) and recalculate the Total.
4. WHEN coin redemption is applied, THE Cart_Service SHALL ensure the Total is never negative; IF the Discount would exceed the Subtotal, THEN THE Cart_Service SHALL cap the Discount at the Subtotal value.
5. WHEN the User deactivates coin redemption, THE Cart_Service SHALL remove the Discount and recalculate the Total.
6. WHEN an authenticated User's Coin_Balance is below 1000, THE Cart screen SHALL hide the coin redemption option.

---

### Requirement 8: Proceed to Checkout

**User Story:** As a signed-in user, I want to proceed to checkout from my cart, so that I can complete my order.

#### Acceptance Criteria

1. WHEN an authenticated User taps "Checkout", THE Cart_Service SHALL validate that the Cart contains at least one CartItem.
2. WHEN the User has selected "Delivery" and has no delivery address, THE Cart_Service SHALL block checkout and prompt the User to add a delivery address.
3. WHEN all validations pass, THE Flutter app SHALL navigate to the Payment Processing screen, passing the Cart summary (items, subtotal, delivery fee, discount, total, delivery option, address).
4. WHEN a CartItem's meal becomes unavailable between cart addition and checkout, THE Cart_Service SHALL flag the unavailable item, block checkout, and prompt the User to remove it.

---

### Requirement 9: Cart Persistence and Sync

**User Story:** As a signed-in user, I want my cart to be saved across sessions, so that I do not lose my selections if I close the app.

#### Acceptance Criteria

1. THE Cart_Service SHALL persist the Cart to local storage (Hive) after every modification.
2. WHEN the app is relaunched, THE Cart_Service SHALL restore the Cart from local storage.
3. WHEN a restored CartItem's meal is no longer available, THE Cart_Service SHALL mark the item as unavailable and notify the User on the Cart screen.
