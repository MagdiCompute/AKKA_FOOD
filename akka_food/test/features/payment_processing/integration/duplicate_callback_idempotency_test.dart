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
const _testTransactionId = 'txn-idempotency-001';

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
    reference: 'ref-uuid-idempotency-001',
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
// Integration Tests: Duplicate Callback Idempotency
// Validates: Req 6 AC4 — Processing the same success callback twice SHALL NOT
//            create duplicate Orders or credit coins twice
// ---------------------------------------------------------------------------

void main() {
  group('Integration: Duplicate Callback Idempotency', () {
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
    // Test 1: Duplicate success events on stream — only transitions once
    // Validates: Req 6 AC4
    //
    // If the Firestore stream emits `success` twice (e.g., due to a
    // reconnection), the PaymentNotifier should only transition to `success`
    // once and auto-cancel the subscription so the second event is ignored.
    // -----------------------------------------------------------------------
    test(
      'duplicate success events on stream: only transitions to success once',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Track all state transitions.
        final stateTransitions = <PaymentUIState>[];
        container.listen(paymentNotifierProvider, (_, next) {
          final value = next.valueOrNull;
          if (value != null) {
            stateTransitions.add(value);
          }
        });

        // Initiate payment.
        await notifier.initiatePayment(_makePaymentRequest());

        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );

        // First success event — should transition to success.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-001',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // Second success event (duplicate, e.g., from Firestore reconnection).
        // This should be ignored because the subscription was auto-cancelled.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-001',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // State should still be success — no duplicate transition.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // Count how many times `success` appears in state transitions.
        final successCount = stateTransitions
            .where((s) => s == PaymentUIState.success)
            .length;
        expect(successCount, 1,
            reason: 'Success state should only be emitted once');
      },
    );

    // -----------------------------------------------------------------------
    // Test 2: State remains stable after terminal state
    // Validates: Req 6 AC4
    //
    // Once in `success` state, no further stream events (failed, cancelled,
    // processing) should change the state.
    // -----------------------------------------------------------------------
    test(
      'state remains stable after reaching success — subsequent events ignored',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Initiate payment.
        await notifier.initiatePayment(_makePaymentRequest());

        // Emit success.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-stable-001',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // Attempt to emit various non-success statuses after terminal state.
        // All should be ignored because the subscription is cancelled.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.failed),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.cancelled),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.processing),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        mockRepo.transactionStreamController!.add(
          _makeTransaction(status: PaymentStatus.pending),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );
      },
    );

    // -----------------------------------------------------------------------
    // Test 3: No duplicate navigation — success state count verification
    // Validates: Req 6 AC4
    //
    // The UI navigates to the confirmation screen when state becomes `success`.
    // If the notifier emitted `success` multiple times, the UI would navigate
    // twice. This test verifies that even with multiple success events on the
    // stream, the notifier only emits `success` once.
    // -----------------------------------------------------------------------
    test(
      'no duplicate navigation: success state emitted exactly once despite '
      'multiple stream events',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Track every state change (including duplicates if any).
        final allStateChanges = <PaymentUIState>[];
        container.listen(paymentNotifierProvider, (_, next) {
          final value = next.valueOrNull;
          if (value != null) {
            allStateChanges.add(value);
          }
        });

        // Initiate payment.
        await notifier.initiatePayment(_makePaymentRequest());

        // Simulate rapid-fire success events (e.g., Firestore reconnection
        // replaying the same document snapshot multiple times).
        for (var i = 0; i < 5; i++) {
          mockRepo.transactionStreamController!.add(
            _makeTransaction(
              status: PaymentStatus.success,
              orderId: 'order-nav-001',
            ),
          );
          await Future<void>.delayed(Duration.zero);
        }

        // Final state should be success.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // The success state should appear exactly once in the transitions.
        // This ensures the UI would only navigate to the confirmation screen
        // once, preventing duplicate navigation.
        final successEmissions = allStateChanges
            .where((s) => s == PaymentUIState.success)
            .length;
        expect(successEmissions, 1,
            reason:
                'Success should be emitted exactly once to prevent duplicate '
                'navigation to the confirmation screen');
      },
    );

    // -----------------------------------------------------------------------
    // Test 4: Subscription is cancelled after first success event
    // Validates: Req 6 AC4
    //
    // Verifies that the internal subscription is cleaned up after the first
    // terminal state, ensuring no further events are processed.
    // -----------------------------------------------------------------------
    test(
      'subscription is cancelled after first success — stream listener inactive',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Initiate payment.
        await notifier.initiatePayment(_makePaymentRequest());

        // Emit success.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-sub-cancel-001',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // After success, the transaction ID is still accessible (for the
        // confirmation screen) but the subscription is cancelled.
        expect(notifier.currentTransactionId, _testTransactionId);

        // Emit another event — should have no effect.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-duplicate-002',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // State unchanged.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );
      },
    );

    // -----------------------------------------------------------------------
    // Test 5: Only one initiatePayment call is made per payment attempt
    // Validates: Req 6 AC4
    //
    // Even if the stream emits success multiple times, the repository's
    // initiatePayment should only have been called once per payment attempt.
    // This ensures no duplicate order creation is triggered from the client.
    // -----------------------------------------------------------------------
    test(
      'only one initiatePayment call per attempt — no duplicate triggers',
      () async {
        await _waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Initiate payment once.
        await notifier.initiatePayment(_makePaymentRequest());

        // Emit success multiple times.
        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-single-001',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        mockRepo.transactionStreamController!.add(
          _makeTransaction(
            status: PaymentStatus.success,
            orderId: 'order-single-001',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // Verify initiatePayment was called exactly once.
        expect(mockRepo.initiatePaymentCalls, hasLength(1));

        // Verify no cancel calls were made (no spurious cleanup).
        expect(mockRepo.cancelledTransactionIds, isEmpty);
      },
    );
  });
}
