import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../datasources/cloud_function_payment_data_source.dart';
import '../datasources/firestore_transaction_data_source.dart';

/// Concrete implementation of [IPaymentRepository].
///
/// Composes two data sources:
/// - [CloudFunctionPaymentDataSource] — initiates and cancels payments via
///   Firebase Cloud Functions (server-side Orange Money API orchestration).
/// - [FirestoreTransactionDataSource] — reads transaction data from Firestore
///   (real-time listeners and paginated history).
///
/// Accepts a [FirebaseAuth] instance to resolve the current user's UID for
/// payment history queries. All dependencies are injected via the constructor
/// for testability.
class PaymentRepository implements IPaymentRepository {
  PaymentRepository({
    required CloudFunctionPaymentDataSource cloudFunctionDataSource,
    required FirestoreTransactionDataSource firestoreDataSource,
    FirebaseAuth? firebaseAuth,
  })  : _cloudFunctionDataSource = cloudFunctionDataSource,
        _firestoreDataSource = firestoreDataSource,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final CloudFunctionPaymentDataSource _cloudFunctionDataSource;
  final FirestoreTransactionDataSource _firestoreDataSource;
  final FirebaseAuth _firebaseAuth;

  // ---------------------------------------------------------------------------
  // IPaymentRepository — payment operations (Cloud Functions)
  // ---------------------------------------------------------------------------

  /// Initiates a payment via the `initiatePayment` Cloud Function.
  ///
  /// Delegates to [CloudFunctionPaymentDataSource.initiatePayment].
  @override
  Future<PaymentResult> initiatePayment(PaymentRequest request) {
    return _cloudFunctionDataSource.initiatePayment(request);
  }

  /// Cancels a pending payment via the `cancelPayment` Cloud Function.
  ///
  /// Delegates to [CloudFunctionPaymentDataSource.cancelPayment].
  @override
  Future<void> cancelPayment(String transactionId) {
    return _cloudFunctionDataSource.cancelPayment(transactionId);
  }

  // ---------------------------------------------------------------------------
  // IPaymentRepository — transaction reads (Firestore)
  // ---------------------------------------------------------------------------

  /// Watches a transaction document for real-time status updates.
  ///
  /// Delegates to [FirestoreTransactionDataSource.watchTransaction].
  @override
  Stream<Transaction> watchTransaction(String transactionId) {
    return _firestoreDataSource.watchTransaction(transactionId);
  }

  /// Returns a paginated list of the current user's transactions, ordered
  /// by `createdAt` descending.
  ///
  /// Converts the page-based interface ([page], [pageSize]) to the
  /// cursor-based pagination used by [FirestoreTransactionDataSource].
  /// For simplicity, pages beyond the first require fetching all preceding
  /// documents to obtain the correct cursor position.
  ///
  /// Throws [StateError] if no user is currently authenticated.
  @override
  Future<List<Transaction>> getPaymentHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    assert(page >= 1, 'page must be >= 1');
    assert(pageSize >= 1, 'pageSize must be >= 1');

    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'Cannot fetch payment history: no authenticated user.',
      );
    }

    // For page 1, fetch directly without a cursor.
    if (page == 1) {
      return _firestoreDataSource.getUserTransactions(uid, limit: pageSize);
    }

    // For subsequent pages, fetch all documents up to the target page to
    // obtain the cursor. This mirrors the pattern used by OrderRepository.
    final skipCount = (page - 1) * pageSize;
    final allUpToPage = await _firestoreDataSource.getUserTransactions(
      uid,
      limit: skipCount + pageSize,
    );

    if (allUpToPage.length <= skipCount) return [];
    return allUpToPage.sublist(skipCount);
  }
}
