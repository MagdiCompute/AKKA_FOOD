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
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Mock repository
// ---------------------------------------------------------------------------

/// Mock implementation of [IPaymentRepository] for timeout integration tests.
class MockPaymentRepository implements IPaymentRepository {
  PaymentResult? initiatePaymentResult;
  StreamController<domain.Transaction>? transactionStreamController;
  final List<PaymentRequest> initiatePaymentCalls = [];
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
const _testTransactionId = 'txn-timeout-001';

PaymentRequest _makePaymentRequest() {
  return const PaymentRequest(
    cartSummary: CartSummary(
      items: [
        CartItem(
          mealId: 'meal-1',
          mealName: 'Riz au Gras',
          mealImageUrl: 'https://example.com/riz.jpg',
          unitPrice: 2000,
          quantity: 2,
          isAvailable: true,
        ),
      ],
      subtotal: 4000,
      deliveryFee: 500,
      discount: 0,
      total: 4500,
      redeemedCoins: 0,
      deliveryOption: DeliveryOption.delivery,
    ),
    phoneNumber: _testPhoneNumber,
  );
}

domain.Transaction _makeTransaction({
  PaymentStatus status = PaymentStatus.pending,
  String? orderId,
}) {
  return domain.Transaction(
    id: _testTransactionId,
    reference: 'ref-uuid-timeout-001',
    uid: 'user-timeout-1',
    amount: 4500,
    status: status,
    orderId: orderId,
    createdAt: DateTime(2024, 6, 15, 10, 0),
    updatedAt: DateTime(2024, 6, 15, 10, 0),
  );
}

// ---------------------------------------------------------------------------
// Integration Tests: Payment Timeout After 5 Minutes
// ---------------------------------------------------------------------------

void main() {
  group('Integration: Payment Timeout After 5 Minutes', () {
    // -----------------------------------------------------------------------
    // Test 1: Timeout fires after 5 minutes
    // -----------------------------------------------------------------------
    test(
      'payment times out after 5 minutes — state transitions to failed',
      () {
        fakeAsync((async) {
          final mockRepo = MockPaymentRepository();
          mockRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          mockRepo.initiatePaymentResult = const PaymentResult(
            transactionId: _testTransactionId,
            status: PaymentStatus.pending,
          );

          final container = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(mockRepo),
            ],
          );
          container.listen(paymentNotifierProvider, (_, __) {});

          final notifier = container.read(paymentNotifierProvider.notifier);

          // Initiate payment — starts the 5-minute timeout timer.
          notifier.initiatePayment(_makePaymentRequest());
          async.flushMicrotasks();

          // Verify state is processing after initiation.
          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.processing,
          );

          // Advance time by exactly 5 minutes — timeout should fire.
          async.elapse(const Duration(minutes: 5));

          // Verify state transitioned to failed due to timeout.
          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.failed,
          );

          container.dispose();
          mockRepo.transactionStreamController?.close();
        });
      },
    );

    // -----------------------------------------------------------------------
    // Test 2: Timeout does NOT fire if success arrives before 5 minutes
    // -----------------------------------------------------------------------
    test(
      'timeout does NOT fire if success arrives before 5 minutes',
      () {
        fakeAsync((async) {
          final mockRepo = MockPaymentRepository();
          mockRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          mockRepo.initiatePaymentResult = const PaymentResult(
            transactionId: _testTransactionId,
            status: PaymentStatus.pending,
          );

          final container = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(mockRepo),
            ],
          );
          container.listen(paymentNotifierProvider, (_, __) {});

          final notifier = container.read(paymentNotifierProvider.notifier);

          // Initiate payment.
          notifier.initiatePayment(_makePaymentRequest());
          async.flushMicrotasks();

          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.processing,
          );

          // Advance 2 minutes, then emit success from Firestore stream.
          async.elapse(const Duration(minutes: 2));
          mockRepo.transactionStreamController!.add(
            _makeTransaction(
              status: PaymentStatus.success,
              orderId: 'order-success-001',
            ),
          );
          async.flushMicrotasks();

          // Verify state is success.
          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.success,
          );

          // Advance past the 5-minute mark — state should remain success.
          async.elapse(const Duration(minutes: 4));

          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.success,
          );

          container.dispose();
          mockRepo.transactionStreamController?.close();
        });
      },
    );

    // -----------------------------------------------------------------------
    // Test 3: Timeout does NOT fire if cancelled before 5 minutes
    // -----------------------------------------------------------------------
    test(
      'timeout does NOT fire if payment is cancelled before 5 minutes',
      () {
        fakeAsync((async) {
          final mockRepo = MockPaymentRepository();
          mockRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          mockRepo.initiatePaymentResult = const PaymentResult(
            transactionId: _testTransactionId,
            status: PaymentStatus.pending,
          );

          final container = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(mockRepo),
            ],
          );
          container.listen(paymentNotifierProvider, (_, __) {});

          final notifier = container.read(paymentNotifierProvider.notifier);

          // Initiate payment.
          notifier.initiatePayment(_makePaymentRequest());
          async.flushMicrotasks();

          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.processing,
          );

          // Advance 1 minute, then cancel the payment.
          async.elapse(const Duration(minutes: 1));
          notifier.cancelPayment(_testTransactionId);
          async.flushMicrotasks();

          // Verify state is cancelled.
          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.cancelled,
          );

          // Advance past the 5-minute mark — state should remain cancelled.
          async.elapse(const Duration(minutes: 5));

          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.cancelled,
          );

          container.dispose();
          mockRepo.transactionStreamController?.close();
        });
      },
    );

    // -----------------------------------------------------------------------
    // Test 4: Timeout fires at exactly 5 minutes (boundary condition)
    // -----------------------------------------------------------------------
    test(
      'timeout fires at exactly 5 minutes — boundary condition',
      () {
        fakeAsync((async) {
          final mockRepo = MockPaymentRepository();
          mockRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          mockRepo.initiatePaymentResult = const PaymentResult(
            transactionId: _testTransactionId,
            status: PaymentStatus.pending,
          );

          final container = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(mockRepo),
            ],
          );
          container.listen(paymentNotifierProvider, (_, __) {});

          final notifier = container.read(paymentNotifierProvider.notifier);

          // Initiate payment.
          notifier.initiatePayment(_makePaymentRequest());
          async.flushMicrotasks();

          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.processing,
          );

          // Advance to 1 millisecond before 5 minutes — should still be
          // processing.
          async.elapse(
            const Duration(minutes: 5) - const Duration(milliseconds: 1),
          );

          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.processing,
          );

          // Advance the final millisecond — timeout fires at exactly 5 min.
          async.elapse(const Duration(milliseconds: 1));

          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.failed,
          );

          container.dispose();
          mockRepo.transactionStreamController?.close();
        });
      },
    );

    // -----------------------------------------------------------------------
    // Test 5: State is processing just before timeout (at 4:59)
    // -----------------------------------------------------------------------
    test(
      'state is still processing at 4 minutes 59 seconds',
      () {
        fakeAsync((async) {
          final mockRepo = MockPaymentRepository();
          mockRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          mockRepo.initiatePaymentResult = const PaymentResult(
            transactionId: _testTransactionId,
            status: PaymentStatus.pending,
          );

          final container = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(mockRepo),
            ],
          );
          container.listen(paymentNotifierProvider, (_, __) {});

          final notifier = container.read(paymentNotifierProvider.notifier);

          // Initiate payment.
          notifier.initiatePayment(_makePaymentRequest());
          async.flushMicrotasks();

          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.processing,
          );

          // Advance to 4 minutes 59 seconds — just before the 5-minute mark.
          async.elapse(const Duration(minutes: 4, seconds: 59));

          // State should still be processing — timeout hasn't fired yet.
          expect(
            container.read(paymentNotifierProvider).value,
            PaymentUIState.processing,
          );

          container.dispose();
          mockRepo.transactionStreamController?.close();
        });
      },
    );
  });
}
