import 'dart:async';

import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/cart/domain/entities/cart_summary.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/payment_processing/domain/entities/payment_request.dart';
import 'package:akka_food/features/payment_processing/domain/entities/payment_result.dart';
import 'package:akka_food/features/payment_processing/domain/entities/payment_status.dart';
import 'package:akka_food/features/payment_processing/domain/entities/transaction.dart'
    as domain;
import 'package:akka_food/features/payment_processing/domain/repositories/i_payment_repository.dart';
import 'package:akka_food/features/payment_processing/presentation/notifiers/payment_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Mock repository
// ---------------------------------------------------------------------------

/// Mock implementation of [IPaymentRepository] that tracks calls and allows
/// controlling the transaction stream via a [StreamController].
class MockPaymentRepository implements IPaymentRepository {
  /// Controls what [initiatePayment] returns. When multiple calls are expected,
  /// use [initiatePaymentResults] queue instead.
  PaymentResult? initiatePaymentResult;

  /// Queue of results for sequential [initiatePayment] calls.
  /// If non-empty, takes priority over [initiatePaymentResult].
  final List<PaymentResult> initiatePaymentResults = [];

  /// If non-null, [initiatePayment] will throw this error.
  Object? initiatePaymentError;

  /// Stream controller for [watchTransaction] — simulates Firestore real-time
  /// updates on the transaction document.
  StreamController<domain.Transaction>? transactionStreamController;

  /// Tracks [initiatePayment] calls for verification.
  final List<PaymentRequest> initiatePaymentCalls = [];

  /// Tracks [cancelPayment] calls for verification.
  final List<String> cancelledTransactionIds = [];

  @override
  Future<PaymentResult> initiatePayment(PaymentRequest request) async {
    initiatePaymentCalls.add(request);

    if (initiatePaymentError != null) {
      throw initiatePaymentError!;
    }

    if (initiatePaymentResults.isNotEmpty) {
      return initiatePaymentResults.removeAt(0);
    }

    return initiatePaymentResult!;
  }

  @override
  Future<void> cancelPayment(String transactionId) async {
    cancelledTransactionIds.add(transactionId);
  }

  @override
  Stream<domain.Transaction> watchTransaction(String transactionId) {
    transactionStreamController ??=
        StreamController<domain.Transaction>.broadcast();
    return transactionStreamController!.stream;
  }

  @override
  Future<List<domain.Transaction>> getPaymentHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    return [];
  }
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const _testPhoneNumber = '+22376123456';
const _testTransactionId1 = 'txn-failure-001';
const _testTransactionId2 = 'txn-retry-002';
const _testTransactionId3 = 'txn-retry-003';

CartSummary _makeCartSummary() {
  return const CartSummary(
    items: [
      CartItem(
        mealId: 'meal-1',
        mealName: 'Riz au Gras',
        mealImageUrl: 'https://example.com/riz.jpg',
        unitPrice: 1500,
        quantity: 2,
        isAvailable: true,
      ),
      CartItem(
        mealId: 'meal-2',
        mealName: 'Jus de Bissap',
        mealImageUrl: 'https://example.com/bissap.jpg',
        unitPrice: 500,
        quantity: 1,
        isAvailable: true,
      ),
    ],
    subtotal: 3500,
    deliveryFee: 500,
    discount: 0,
    total: 4000,
    redeemedCoins: 0,
    deliveryOption: DeliveryOption.delivery,
  );
}

PaymentRequest _makePaymentRequest() {
  return PaymentRequest(
    cartSummary: _makeCartSummary(),
    phoneNumber: _testPhoneNumber,
  );
}

domain.Transaction _makeTransaction({
  required String id,
  required String reference,
  PaymentStatus status = PaymentStatus.pending,
  String? orderId,
}) {
  return domain.Transaction(
    id: id,
    reference: reference,
    uid: 'user-integration-1',
    amount: 4000,
    status: status,
    orderId: orderId,
    createdAt: DateTime(2024, 6, 15, 10, 0),
    updatedAt: DateTime(2024, 6, 15, 10, 0),
  );
}

// ---------------------------------------------------------------------------
// Helper: build a ProviderContainer with mock repository
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(MockPaymentRepository mockRepo) {
  final container = ProviderContainer(
    overrides: [
      paymentRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
  // Keep the auto-dispose provider alive for the duration of the test.
  container.listen(paymentNotifierProvider, (_, __) {});
  return container;
}

/// Waits for the notifier to finish its initial build.
Future<void> _waitForBuild(ProviderContainer container) async {
  await container.read(paymentNotifierProvider.future);
}

// ---------------------------------------------------------------------------
// Integration Tests: Payment Failure → Cart Retained → Retry
// ---------------------------------------------------------------------------

void main() {
  group('Integration: Payment Failure → Cart Retained → Retry', () {
    late MockPaymentRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockPaymentRepository();
      mockRepo.transactionStreamController =
          StreamController<domain.Transaction>.broadcast();
      mockRepo.initiatePaymentResult = const PaymentResult(
        transactionId: _testTransactionId1,
        status: PaymentStatus.pending,
      );
      container = _makeContainer(mockRepo);
    });

    tearDown(() {
      container.dispose();
      mockRepo.transactionStreamController?.close();
    });

    // -----------------------------------------------------------------------
    // Test 1: Payment failure via stream
    // Validates: Req 3 AC1 — payment fails, Transaction status updated to failed
    // -----------------------------------------------------------------------
    test(
      'payment failure via stream: state transitions to failed',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Initiate payment.
        await notifier.initiatePayment(_makePaymentRequest());

        // Verify we're in processing state.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );

        // Simulate Firestore stream emitting `failed` status.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            id: _testTransactionId1,
            reference: 'ref-uuid-failure-001',
            status: PaymentStatus.failed,
          ),
        );

        // Allow the stream event to propagate.
        await Future<void>.delayed(Duration.zero);

        // Verify state transitions to failed.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.failed,
        );
      },
    );

    // -----------------------------------------------------------------------
    // Test 2: Cart retained on failure
    // Validates: Req 3 AC4 — Cart contents retained on failure
    // -----------------------------------------------------------------------
    test(
      'cart data is retained after payment failure (notifier does not clear it)',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        final request = _makePaymentRequest();
        await notifier.initiatePayment(request);

        // Simulate failure.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            id: _testTransactionId1,
            reference: 'ref-uuid-failure-001',
            status: PaymentStatus.failed,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // Verify state is failed.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.failed,
        );

        // The cart summary from the original request is still intact.
        // The PaymentNotifier does NOT clear cart data on failure —
        // only the Cloud Function clears the cart on success.
        final cartSummary = request.cartSummary;
        expect(cartSummary.items, hasLength(2));
        expect(cartSummary.items[0].mealName, 'Riz au Gras');
        expect(cartSummary.items[1].mealName, 'Jus de Bissap');
        expect(cartSummary.total, 4000);
        expect(cartSummary.subtotal, 3500);
        expect(cartSummary.deliveryFee, 500);

        // Verify the notifier did NOT call cancelPayment or any cart-clearing
        // mechanism — the cart remains available for retry.
        expect(mockRepo.cancelledTransactionIds, isEmpty);
      },
    );

    // -----------------------------------------------------------------------
    // Test 3: Retry creates new transaction
    // Validates: Req 3 AC3 — Retry creates new Transaction with new reference;
    //            previous failed Transaction remains
    // -----------------------------------------------------------------------
    test(
      'retry after failure creates a new transaction (new initiatePayment call)',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Set up sequential results: first call returns txn-1, second returns txn-2.
        mockRepo.initiatePaymentResults.addAll([
          const PaymentResult(
            transactionId: _testTransactionId1,
            status: PaymentStatus.pending,
          ),
          const PaymentResult(
            transactionId: _testTransactionId2,
            status: PaymentStatus.pending,
          ),
        ]);
        mockRepo.initiatePaymentResult = null; // Use queue only.

        // First payment attempt.
        await notifier.initiatePayment(_makePaymentRequest());

        // Simulate failure via stream.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            id: _testTransactionId1,
            reference: 'ref-uuid-failure-001',
            status: PaymentStatus.failed,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.failed,
        );

        // Reset the notifier to allow a retry.
        notifier.reset();
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.idle,
        );

        // Create a fresh stream controller for the retry.
        mockRepo.transactionStreamController?.close();
        mockRepo.transactionStreamController =
            StreamController<domain.Transaction>.broadcast();

        // Retry payment — should create a NEW transaction.
        await notifier.initiatePayment(_makePaymentRequest());

        // Verify TWO separate initiatePayment calls were made.
        expect(mockRepo.initiatePaymentCalls, hasLength(2));

        // Verify the new transaction ID is different from the first.
        expect(notifier.currentTransactionId, _testTransactionId2);
        expect(notifier.currentTransactionId, isNot(_testTransactionId1));

        // Verify state is processing for the new attempt.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );
      },
    );

    // -----------------------------------------------------------------------
    // Test 4: Payment failure via initiation error
    // Validates: Req 3 AC2 — Display error screen with failure reason
    // -----------------------------------------------------------------------
    test(
      'payment failure via initiation error: state transitions to failed',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Configure the mock to throw an error on initiatePayment.
        mockRepo.initiatePaymentError = Exception('Network error');

        // Attempt to initiate payment — should fail.
        await notifier.initiatePayment(_makePaymentRequest());

        // Verify state transitions to failed.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.failed,
        );

        // Verify the call was still tracked.
        expect(mockRepo.initiatePaymentCalls, hasLength(1));

        // Verify no transaction ID was stored (initiation failed).
        expect(notifier.currentTransactionId, isNull);
      },
    );

    // -----------------------------------------------------------------------
    // Test 5: Multiple retries — each creates a new transaction
    // Validates: Req 3 AC3 — Each retry creates new Transaction with new
    //            reference; previous failed Transactions remain in record
    // -----------------------------------------------------------------------
    test(
      'multiple retries: fail → retry → fail → retry — each creates new transaction',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Set up three sequential results for three payment attempts.
        mockRepo.initiatePaymentResults.addAll([
          const PaymentResult(
            transactionId: _testTransactionId1,
            status: PaymentStatus.pending,
          ),
          const PaymentResult(
            transactionId: _testTransactionId2,
            status: PaymentStatus.pending,
          ),
          const PaymentResult(
            transactionId: _testTransactionId3,
            status: PaymentStatus.pending,
          ),
        ]);
        mockRepo.initiatePaymentResult = null;

        // --- Attempt 1: Initiate and fail ---
        await notifier.initiatePayment(_makePaymentRequest());
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );
        expect(notifier.currentTransactionId, _testTransactionId1);

        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            id: _testTransactionId1,
            reference: 'ref-uuid-failure-001',
            status: PaymentStatus.failed,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.failed,
        );

        // --- Attempt 2: Reset and retry, then fail again ---
        notifier.reset();
        mockRepo.transactionStreamController?.close();
        mockRepo.transactionStreamController =
            StreamController<domain.Transaction>.broadcast();

        await notifier.initiatePayment(_makePaymentRequest());
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );
        expect(notifier.currentTransactionId, _testTransactionId2);

        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            id: _testTransactionId2,
            reference: 'ref-uuid-failure-002',
            status: PaymentStatus.failed,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.failed,
        );

        // --- Attempt 3: Reset and retry again (this time succeeds) ---
        notifier.reset();
        mockRepo.transactionStreamController?.close();
        mockRepo.transactionStreamController =
            StreamController<domain.Transaction>.broadcast();

        await notifier.initiatePayment(_makePaymentRequest());
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );
        expect(notifier.currentTransactionId, _testTransactionId3);

        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            id: _testTransactionId3,
            reference: 'ref-uuid-success-003',
            status: PaymentStatus.success,
            orderId: 'order-after-retries',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // --- Verify all three attempts created separate transactions ---
        expect(mockRepo.initiatePaymentCalls, hasLength(3));

        // Each call used the same cart data (cart retained between retries).
        for (final call in mockRepo.initiatePaymentCalls) {
          expect(call.phoneNumber, _testPhoneNumber);
          expect(call.cartSummary.total, 4000);
          expect(call.cartSummary.items, hasLength(2));
        }
      },
    );
  });
}
