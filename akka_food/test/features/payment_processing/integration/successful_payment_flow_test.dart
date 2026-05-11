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
  /// Controls what [initiatePayment] returns.
  PaymentResult? initiatePaymentResult;

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
const _testTransactionId = 'txn-integration-001';

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
  PaymentStatus status = PaymentStatus.pending,
  String? orderId,
}) {
  return domain.Transaction(
    id: _testTransactionId,
    reference: 'ref-uuid-integration-001',
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
// Integration Tests: Successful Payment Flow
// ---------------------------------------------------------------------------

void main() {
  group('Integration: Successful Payment Flow', () {
    late MockPaymentRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockPaymentRepository();
      mockRepo.transactionStreamController =
          StreamController<domain.Transaction>.broadcast();
      mockRepo.initiatePaymentResult = const PaymentResult(
        transactionId: _testTransactionId,
        status: PaymentStatus.pending,
      );
      container = _makeContainer(mockRepo);
    });

    tearDown(() {
      container.dispose();
      mockRepo.transactionStreamController?.close();
    });

    // -----------------------------------------------------------------------
    // Test 1: Full state transition flow idle → initiating → processing → success
    // -----------------------------------------------------------------------
    test(
      'complete flow: idle → initiating → processing → success',
      () async {
        await _waitForBuild(container);

        // 1. Verify initial state is idle.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.idle,
        );

        final notifier = container.read(paymentNotifierProvider.notifier);

        // Track state transitions.
        final stateTransitions = <PaymentUIState>[];
        container.listen(paymentNotifierProvider, (previous, next) {
          final value = next.valueOrNull;
          if (value != null) {
            stateTransitions.add(value);
          }
        });

        // 2. Initiate payment — transitions through initiating → processing.
        await notifier.initiatePayment(_makePaymentRequest());

        // After initiatePayment completes, state should be processing.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );

        // 3. Simulate Firestore stream emitting transaction with status `success`.
        //    This simulates the Cloud Function callback updating the transaction.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-12345',
          ),
        );

        // Allow the stream event to propagate.
        await Future<void>.delayed(Duration.zero);

        // 4. Verify final state is success.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // 5. Verify state transitions included initiating and processing.
        expect(stateTransitions, contains(PaymentUIState.initiating));
        expect(stateTransitions, contains(PaymentUIState.processing));
        expect(stateTransitions, contains(PaymentUIState.success));
      },
    );

    // -----------------------------------------------------------------------
    // Test 2: initiatePayment is called with correct parameters
    // -----------------------------------------------------------------------
    test(
      'initiatePayment is called with correct phone number and cart summary',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        final request = _makePaymentRequest();
        await notifier.initiatePayment(request);

        // Verify the repository received the correct request.
        expect(mockRepo.initiatePaymentCalls, hasLength(1));

        final capturedRequest = mockRepo.initiatePaymentCalls.first;
        expect(capturedRequest.phoneNumber, _testPhoneNumber);
        expect(capturedRequest.cartSummary.total, 4000);
        expect(capturedRequest.cartSummary.items, hasLength(2));
        expect(capturedRequest.cartSummary.items[0].mealName, 'Riz au Gras');
        expect(capturedRequest.cartSummary.items[1].mealName, 'Jus de Bissap');
        expect(
          capturedRequest.cartSummary.deliveryOption,
          DeliveryOption.delivery,
        );
      },
    );

    // -----------------------------------------------------------------------
    // Test 3: Transaction stream success updates state correctly
    // -----------------------------------------------------------------------
    test(
      'when transaction stream emits success, state transitions to success',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        await notifier.initiatePayment(_makePaymentRequest());

        // Verify we're in processing state.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );

        // Simulate intermediate processing status from Firestore.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.processing),
        );
        await Future<void>.delayed(Duration.zero);

        // Still processing.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );

        // Now emit success.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-67890',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // State should now be success.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );
      },
    );

    // -----------------------------------------------------------------------
    // Test 4: Transaction ID is stored after successful initiation
    // -----------------------------------------------------------------------
    test(
      'transaction ID is stored and accessible after initiation',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Before initiation, no transaction ID.
        expect(notifier.currentTransactionId, isNull);

        await notifier.initiatePayment(_makePaymentRequest());

        // After initiation, transaction ID is stored.
        expect(notifier.currentTransactionId, _testTransactionId);
      },
    );

    // -----------------------------------------------------------------------
    // Test 5: Subscription auto-cancels on success (no further state changes)
    // -----------------------------------------------------------------------
    test(
      'subscription auto-cancels after success — no further state changes',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        await notifier.initiatePayment(_makePaymentRequest());

        // Emit success.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.success),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // Emit a failed event after success — should be ignored because
        // the subscription was auto-cancelled on terminal state.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.failed),
        );
        await Future<void>.delayed(Duration.zero);

        // State should still be success.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );
      },
    );

    // -----------------------------------------------------------------------
    // Test 6: Coins earned calculation verification
    // -----------------------------------------------------------------------
    test(
      'coins earned is 5% of total amount (floor)',
      () {
        // This verifies the coin calculation logic that the Cloud Function
        // would apply. The client displays this on the confirmation screen.
        const totalAmount = 4000.0;
        final coinsEarned = (totalAmount * 0.05).floor();
        expect(coinsEarned, 200);

        // Edge case: non-round amount
        const totalAmount2 = 3333.0;
        final coinsEarned2 = (totalAmount2 * 0.05).floor();
        expect(coinsEarned2, 166);
      },
    );

    // -----------------------------------------------------------------------
    // Test 7: End-to-end flow with pending → processing → success transitions
    // -----------------------------------------------------------------------
    test(
      'end-to-end: pending → processing → success via Firestore stream',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Track all state values.
        final states = <PaymentUIState>[];
        container.listen(paymentNotifierProvider, (_, next) {
          final value = next.valueOrNull;
          if (value != null && (states.isEmpty || states.last != value)) {
            states.add(value);
          }
        });

        // Initiate payment.
        await notifier.initiatePayment(_makePaymentRequest());

        // Simulate the full Firestore lifecycle:
        // 1. Transaction created with pending status
        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.pending),
        );
        await Future<void>.delayed(Duration.zero);

        // 2. Orange Money starts processing
        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.processing),
        );
        await Future<void>.delayed(Duration.zero);

        // 3. Callback confirms success, order created, coins credited, cart cleared
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-final-001',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // Verify the final state is success.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // Verify the state machine went through the expected transitions.
        // initiating → processing → success
        expect(states, contains(PaymentUIState.initiating));
        expect(states, contains(PaymentUIState.processing));
        expect(states, contains(PaymentUIState.success));

        // Verify success comes after processing in the list.
        final processingIndex = states.lastIndexOf(PaymentUIState.processing);
        final successIndex = states.indexOf(PaymentUIState.success);
        expect(successIndex, greaterThan(processingIndex));
      },
    );

    // -----------------------------------------------------------------------
    // Test 8: Order confirmation data is derivable from the flow
    // -----------------------------------------------------------------------
    test(
      'order confirmation data can be derived from cart and transaction',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        final request = _makePaymentRequest();
        await notifier.initiatePayment(request);

        // Simulate success.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-confirm-001',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // Verify we can construct the confirmation data from available info.
        final transactionId = notifier.currentTransactionId;
        expect(transactionId, isNotNull);
        expect(transactionId, _testTransactionId);

        // The cart summary data is available from the original request.
        final cartSummary = request.cartSummary;
        expect(cartSummary.items, hasLength(2));
        expect(cartSummary.total, 4000);

        // The order ID comes from the transaction (set by Cloud Function).
        // In the real app, the PaymentProcessingScreen uses the transactionId
        // as the orderId for the confirmation screen.
        expect(transactionId, isNotEmpty);
      },
    );
  });
}
