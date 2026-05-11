import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_summary.freezed.dart';
part 'cart_summary.g.dart';

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
// CartSummary DTO
// ---------------------------------------------------------------------------

/// Data Transfer Object passed to the Payment Processing screen at checkout.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability and [json_serializable] for serialization.
///
/// This is a snapshot of the cart at the moment the user proceeds to checkout,
/// with all computed values pre-calculated.
@freezed
abstract class CartSummary with _$CartSummary {
  const CartSummary._();

  const factory CartSummary({
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double total,
    required int redeemedCoins,
    required DeliveryOption deliveryOption,
    @_DeliveryAddressConverter() DeliveryAddress? deliveryAddress,
  }) = _CartSummary;

  factory CartSummary.fromJson(Map<String, dynamic> json) =>
      _$CartSummaryFromJson(json);
}
