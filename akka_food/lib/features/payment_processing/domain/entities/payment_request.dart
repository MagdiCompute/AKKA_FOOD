import 'package:akka_food/features/cart/domain/entities/cart_summary.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_request.freezed.dart';
part 'payment_request.g.dart';

/// Data Transfer Object representing a payment initiation request.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
/// Uses [json_serializable] for JSON serialization.
///
/// Contains the cart snapshot and the user's Orange Money phone number.
@Freezed(toJson: true, fromJson: true)
abstract class PaymentRequest with _$PaymentRequest {
  const PaymentRequest._();

  @JsonSerializable(explicitToJson: true)
  const factory PaymentRequest({
    /// The cart summary containing items and total at checkout time.
    required CartSummary cartSummary,

    /// The user's Orange Money Mali phone number.
    required String phoneNumber,
  }) = _PaymentRequest;

  factory PaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestFromJson(json);

  /// Creates a [PaymentRequest] from a map (Firestore-compatible alias).
  factory PaymentRequest.fromMap(Map<String, dynamic> map) =>
      PaymentRequest.fromJson(map);

  /// Converts this [PaymentRequest] to a map suitable for Firestore writes.
  Map<String, dynamic> toMap() => toJson();
}
