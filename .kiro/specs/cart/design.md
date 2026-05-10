# Design Document — Cart

## Overview

The Cart is a client-side feature persisted locally with Hive. It integrates with the Meal Catalog (meal availability checks), Coin_Service (redemption), and Payment Processing (checkout handoff). Riverpod manages cart state reactively.

---

## Architecture

```
Presentation Layer
  └── Screens: CartScreen, CheckoutSummaryScreen
  └── Widgets: CartItemTile, CartSummaryCard, DeliveryToggle, CoinRedemptionCard
  └── State: CartNotifier (Riverpod)

Domain Layer
  └── Entities: Cart, CartItem, CartSummary
  └── Use Cases: AddToCartUseCase, RemoveFromCartUseCase, UpdateQuantityUseCase,
                 ClearCartUseCase, ApplyCoinRedemptionUseCase, SetDeliveryOptionUseCase,
                 ValidateCartUseCase

Data Layer
  └── CartRepository
  └── HiveCartDataSource (local persistence)
  └── MealAvailabilityChecker (calls MealRepository to validate items at checkout)
```

---

## Data Models

### CartItem
```dart
class CartItem {
  final String mealId;
  final String mealName;
  final String mealImageUrl;
  final double unitPrice;
  int quantity;           // 1–20
  bool isAvailable;       // re-validated at checkout
}
```

### Cart
```dart
class Cart {
  final List<CartItem> items;
  final DeliveryOption deliveryOption; // DeliveryOption.delivery | DeliveryOption.pickup
  final DeliveryAddress? selectedAddress;
  final int redeemedCoins;   // 0 or multiple of 1000

  double get subtotal => items.fold(0, (sum, i) => sum + i.unitPrice * i.quantity);
  double get deliveryFee => deliveryOption == DeliveryOption.delivery ? 500.0 : 0.0; // XOF
  double get discount => redeemedCoins.toDouble();
  double get total => max(0, subtotal + deliveryFee - discount);
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}
```

### CartSummary (passed to Payment screen)
```dart
class CartSummary {
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final int redeemedCoins;
  final DeliveryOption deliveryOption;
  final DeliveryAddress? deliveryAddress;
}
```

---

## State Management (Riverpod)

```dart
class CartNotifier extends Notifier<Cart> {
  void addItem(Meal meal);
  void removeItem(String mealId);
  void updateQuantity(String mealId, int quantity);
  void clearCart();
  void setDeliveryOption(DeliveryOption option);
  void setDeliveryAddress(DeliveryAddress address);
  void applyCoins(int coinBalance);   // calculates max redeemable
  void removeCoins();
  Future<CartValidationResult> validateForCheckout();
}
```

Cart state is persisted to Hive on every `state = ...` assignment via a listener:

```dart
ref.listen(cartProvider, (_, cart) => cartRepository.save(cart));
```

---

## Hive Persistence

```dart
// Hive box
HiveBox<Map>('cart')  // serialized Cart JSON

// On app start
final savedCart = await cartRepository.load();
if (savedCart != null) state = savedCart;
```

---

## Coin Redemption Logic

```dart
int calculateMaxRedeemableCoins(int coinBalance, double subtotal) {
  final maxByBalance = (coinBalance ~/ 1000) * 1000;
  final maxBySubtotal = subtotal.floor(); // 1 coin = 1 XOF
  final maxRedeemable = min(maxByBalance, maxBySubtotal);
  return (maxRedeemable ~/ 1000) * 1000; // round down to nearest 1000
}
```

---

## Checkout Validation

```dart
class CartValidationResult {
  final bool isValid;
  final List<String> unavailableMealIds;
  final bool missingDeliveryAddress;
  final bool emptyCart;
}
```

Validation steps:
1. Cart is not empty
2. All CartItems have `isAvailable == true` (re-checked against Firestore)
3. If delivery selected: `selectedAddress != null`

---

## Navigation Flow

```
MealDetailScreen
  └── "Add to Cart" → CartNotifier.addItem() → snackbar confirmation

CartScreen (accessible via bottom nav cart icon)
  ├── Quantity controls → CartNotifier.updateQuantity()
  ├── Swipe to remove → CartNotifier.removeItem()
  ├── Delivery/Pickup toggle → CartNotifier.setDeliveryOption()
  ├── Address selector → AddressListScreen (returns selected address)
  ├── Coin redemption toggle → CartNotifier.applyCoins() / removeCoins()
  └── "Checkout" → validate → PaymentScreen(cartSummary)
```

---

## Delivery Fee

Delivery fee is a fixed constant (500 XOF) stored in a remote config (Firebase Remote Config) so it can be updated without an app release.

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Adding unavailable meal | Snackbar: "This item is currently unavailable" |
| Quantity exceeds 20 | Cap at 20, show warning snackbar |
| Checkout with unavailable item | Highlight item in red, block checkout, show "Remove unavailable items" |
| Checkout with no address (delivery) | Scroll to address section, show inline error |
| Hive save fails | Log error silently; cart still works in-memory |
