import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_validation_result.freezed.dart';

/// Result of validating the cart before proceeding to checkout.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// [isValid] is `true` only when all validation checks pass:
/// - Cart is not empty ([emptyCart] == false)
/// - All items are available ([unavailableMealIds] is empty)
/// - Delivery address is present when required ([missingDeliveryAddress] == false)
@freezed
abstract class CartValidationResult with _$CartValidationResult {
  const CartValidationResult._();

  const factory CartValidationResult({
    required bool isValid,
    required List<String> unavailableMealIds,
    required bool missingDeliveryAddress,
    required bool emptyCart,
  }) = _CartValidationResult;

  // ---------------------------------------------------------------------------
  // Factory helpers
  // ---------------------------------------------------------------------------

  /// Returns a valid result with no issues.
  factory CartValidationResult.valid() => const CartValidationResult(
        isValid: true,
        unavailableMealIds: [],
        missingDeliveryAddress: false,
        emptyCart: false,
      );
}
