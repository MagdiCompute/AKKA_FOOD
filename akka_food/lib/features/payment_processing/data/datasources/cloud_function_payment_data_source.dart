import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/entities/payment_status.dart';

/// Data source that calls Firebase Cloud Functions for payment operations.
///
/// The Flutter app never calls the Orange Money API directly — all payment
/// logic is orchestrated server-side via Cloud Functions. This class is the
/// bridge between the Flutter data layer and those functions.
///
/// Accepts an optional [FirebaseFunctions] instance for testability;
/// defaults to [FirebaseFunctions.instance] in production.
class CloudFunctionPaymentDataSource {
  CloudFunctionPaymentDataSource({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Initiates a payment via the `initiatePayment` Cloud Function.
  ///
  /// Sends the cart total amount and the user's Orange Money phone number.
  /// Optionally includes an [orderId] if retrying a payment for an existing
  /// order reference.
  ///
  /// Returns a [PaymentResult] containing the transaction ID and initial
  /// status (`pending`).
  ///
  /// Throws:
  /// - [PaymentInitiationException] if the Cloud Function returns an error.
  /// - [PaymentNetworkException] if a network error occurs.
  Future<PaymentResult> initiatePayment(PaymentRequest request) async {
    try {
      final callable = _functions.httpsCallable('initiatePayment');

      final response = await callable.call<Map<String, dynamic>>({
        'amount': request.cartSummary.total,
        'phoneNumber': request.phoneNumber,
        'cartItems': request.cartSummary.items
            .map((item) => <String, dynamic>{
                  'mealId': item.mealId,
                  'mealName': item.mealName,
                  'unitPrice': item.unitPrice,
                  'quantity': item.quantity,
                })
            .toList(),
        'subtotal': request.cartSummary.subtotal,
        'deliveryFee': request.cartSummary.deliveryFee,
        'discount': request.cartSummary.discount,
        'redeemedCoins': request.cartSummary.redeemedCoins,
      });

      final data = response.data;

      return PaymentResult(
        transactionId: data['transactionId'] as String,
        status: PaymentStatus.pending,
        orderId: data['orderId'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      throw PaymentInitiationException(
        e.message ?? 'Payment initiation failed.',
        code: e.code,
        details: e.details,
      );
    } on Exception catch (e) {
      throw PaymentNetworkException(
        'Network error during payment initiation: $e',
      );
    }
  }

  /// Cancels a pending payment via the `cancelPayment` Cloud Function.
  ///
  /// Throws:
  /// - [PaymentCancellationException] if the Cloud Function returns an error.
  /// - [PaymentNetworkException] if a network error occurs.
  Future<void> cancelPayment(String transactionId) async {
    try {
      final callable = _functions.httpsCallable('cancelPayment');

      await callable.call<Map<String, dynamic>>({
        'transactionId': transactionId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw PaymentCancellationException(
        e.message ?? 'Payment cancellation failed.',
        code: e.code,
        details: e.details,
      );
    } on Exception catch (e) {
      throw PaymentNetworkException(
        'Network error during payment cancellation: $e',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Thrown when the `initiatePayment` Cloud Function fails.
class PaymentInitiationException implements Exception {
  PaymentInitiationException(this.message, {this.code, this.details});

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() =>
      'PaymentInitiationException: $message (code: $code, details: $details)';
}

/// Thrown when the `cancelPayment` Cloud Function fails.
class PaymentCancellationException implements Exception {
  PaymentCancellationException(this.message, {this.code, this.details});

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() =>
      'PaymentCancellationException: $message (code: $code, details: $details)';
}

/// Thrown when a network error prevents communication with Cloud Functions.
class PaymentNetworkException implements Exception {
  PaymentNetworkException(this.message);

  final String message;

  @override
  String toString() => 'PaymentNetworkException: $message';
}
