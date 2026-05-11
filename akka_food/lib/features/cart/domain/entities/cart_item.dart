import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

/// Domain entity representing a single item in the cart.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
/// Uses [json_serializable] for JSON serialization (Hive persistence).
///
/// [quantity] is constrained to 1–20 by the CartNotifier; the entity itself
/// stores whatever value is provided.
@freezed
abstract class CartItem with _$CartItem {
  const CartItem._();

  const factory CartItem({
    required String mealId,
    required String mealName,
    required String mealImageUrl,
    required double unitPrice,
    required int quantity,
    required bool isAvailable,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Total price for this line item (unitPrice × quantity).
  double get lineTotal => unitPrice * quantity;
}
