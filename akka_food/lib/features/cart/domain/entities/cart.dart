import 'dart:math' show max;

import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart.freezed.dart';
part 'cart.g.dart';

// ---------------------------------------------------------------------------
// JsonConverter for DeliveryAddress
// ---------------------------------------------------------------------------

/// Converts [DeliveryAddress] to/from a JSON map using its [fromMap]/[toMap]
/// methods, keeping the domain layer free of Firebase imports.
class _DeliveryAddressConverter
    implements JsonConverter<DeliveryAddress, Map<String, dynamic>> {
  const _DeliveryAddressConverter();

  @override
  DeliveryAddress fromJson(Map<String, dynamic> json) =>
      DeliveryAddress.fromMap(json);

  @override
  Map<String, dynamic> toJson(DeliveryAddress address) => address.toMap();
}

// ---------------------------------------------------------------------------
// Cart entity
// ---------------------------------------------------------------------------

/// Domain entity representing the user's current shopping cart.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
/// Uses [json_serializable] for JSON serialization (Hive persistence).
///
/// Computed properties ([subtotal], [deliveryFee], [discount], [total],
/// [itemCount]) are defined in the private constructor body using the
/// `const ClassName._()` pattern supported by freezed.
@freezed
abstract class Cart with _$Cart {
  const Cart._();

  const factory Cart({
    required List<CartItem> items,
    required DeliveryOption deliveryOption,
    @_DeliveryAddressConverter() DeliveryAddress? selectedAddress,
    @Default(0) int redeemedCoins,
  }) = _Cart;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Sum of (unitPrice × quantity) for all items.
  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.unitPrice * item.quantity);

  /// Delivery fee in XOF: 500 for delivery, 0 for pickup.
  double get deliveryFee =>
      deliveryOption == DeliveryOption.delivery ? 500.0 : 0.0;

  /// Discount applied via coin redemption (1 coin = 1 XOF).
  double get discount => redeemedCoins.toDouble();

  /// Final total: max(0, subtotal + deliveryFee − discount).
  double get total => max(0.0, subtotal + deliveryFee - discount);

  /// Sum of all item quantities.
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // ---------------------------------------------------------------------------
  // Factory helpers
  // ---------------------------------------------------------------------------

  /// Returns an empty cart with delivery as the default option.
  factory Cart.empty() => const Cart(
        items: [],
        deliveryOption: DeliveryOption.delivery,
      );
}
