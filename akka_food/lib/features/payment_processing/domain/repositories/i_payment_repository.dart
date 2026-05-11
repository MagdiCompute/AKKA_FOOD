import '../entities/payment_request.dart';
import '../entities/payment_result.dart';
import '../entities/transaction.dart';

/// Abstract repository interface for payment operations.
///
/// Defines the contract for initiating, cancelling, and monitoring payments
/// via Orange Money Mali. Implementations live in the data layer.
///
/// Pure Dart — no Flutter or Firebase imports.
abstract class IPaymentRepository {
  /// Initiates a payment with Orange Money Mali.
  ///
  /// Creates a transaction record and triggers the Orange Money USSD push
  /// to the user's phone.
  Future<PaymentResult> initiatePayment(PaymentRequest request);

  /// Cancels a pending payment.
  ///
  /// Updates the transaction status to `cancelled`. Only valid for
  /// transactions that have not yet been confirmed by Orange Money.
  Future<void> cancelPayment(String transactionId);

  /// Watches a transaction for real-time status updates.
  ///
  /// Returns a stream that emits the latest [Transaction] state whenever
  /// the Firestore document changes (e.g., status transitions from
  /// `pending` → `processing` → `success`).
  Stream<Transaction> watchTransaction(String transactionId);

  /// Gets paginated payment history for the current user.
  ///
  /// Returns transactions ordered by timestamp descending.
  /// [page] is 1-indexed; [pageSize] defaults to 20.
  Future<List<Transaction>> getPaymentHistory({int page, int pageSize});
}
