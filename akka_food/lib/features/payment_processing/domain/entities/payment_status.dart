/// Payment status values for a [Transaction].
///
/// Represents the lifecycle of a payment attempt:
/// - [pending] — payment initiated, awaiting Orange Money confirmation
/// - [processing] — Orange Money is processing the payment
/// - [success] — payment confirmed by Orange Money callback
/// - [failed] — payment failed or timed out
/// - [cancelled] — user cancelled before confirmation
/// - [refunded] — payment was refunded after success
enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  refunded;

  /// Parses a [PaymentStatus] from its string [name].
  ///
  /// Returns [PaymentStatus.pending] if [value] is null or unrecognized.
  static PaymentStatus fromString(String? value) {
    if (value == null) return PaymentStatus.pending;
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}
