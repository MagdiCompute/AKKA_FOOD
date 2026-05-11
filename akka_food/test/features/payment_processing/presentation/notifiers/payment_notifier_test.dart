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

class MockPaymentRepository implements IPaymentRepository {
  /// Controls what [initiatePayment] returns or throws.
  PaymentResult? initiatePaymentResult;
  Object? initiatePaymentError;

  /// Controls what [cancelPayment] does.
  Object? cancelPaymentError;

  /// Stream controller for [watchTransaction].
  StreamController<domain.Transaction>? transactionStreamController;

  /// Tracks calls for verification.
  final List<String> cancelledTransactionIds = [];

  @override
  Future<PaymentResult> initiatePayment(PaymentRequest request) async {
    if (initiatePaymentError != null) {
      throw initiatePaymentError!;
    }
    return initiatePaymentResult!;
  }

  @override
  Future<void> cancelPayment(String transactionId) async {
    cancelledTransactionIds.add(transactionId);
    if (cancelPaymentError != null) {
      throw cancelPaymentError!;
    }
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

PaymentRequest makePaymentRequest({
  String phoneNumber = '+22370000000',
  double total = 5000,
}) {
  return PaymentRequest(
    cartSummary: CartSummary(
      items: [
        const CartItem(
          mealId: 'meal-1',
          mealName: 'Test Meal',
          mealImageUrl: 'https://example.com/meal.jpg',
          unitPrice: 2500,
          quantity: 2,
          isAvailable: true,
        ),
      ],
      subtotal: total,
      deliveryFee: 0,
      discount: 0,
      total: total,
      redeemedCoins: 0,
      deliveryOption: DeliveryOption.delivery,
    ),
    phoneNumber: phoneNumber,
  );
}

domain.Transaction makeTransaction({
  String id = 'txn-123',
  PaymentStatus status = PaymentStatus.pending,
}) {
  return domain.Transaction(
    id: id,
    reference: 'ref-uuid-123',
    uid: 'user-1',
    amount: 5000,
    status: status,
    createdAt: DateTime(2024, 6, 1),
    updatedAt: DateTime(2024, 6, 1),
  );
}

// ---------------------------------------------------------------------------
// Helper: build a ProviderContainer with mock repository and keep alive
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] with the mock repository and keeps the
/// notifier provider alive by listening to it.
ProviderContainer makeContainer(MockPaymentRepository mockRepo) {
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
Future<void> waitForBuild(ProviderContainer container) async {
  await container.read(paymentNotifierProvider.future);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PaymentNotifier', () {
    late MockPaymentRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockPaymentRepository();
      mockRepo.transactionStreamController =
          StreamController<domain.Transaction>.broadcast();
      container = makeContainer(mockRepo);
    });

    tearDown(() {
      container.dispose();
      mockRepo.transactionStreamController?.close();
    });

    // -----------------------------------------------------------------------
    // 1. Initial state
    // -----------------------------------------------------------------------
    group('initial state', () {
      test('starts as PaymentUIState.idle', () async {
        await waitForBuild(container);

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.idle);
      });
    });

    // -----------------------------------------------------------------------
    // 2. initiatePayment
    // -----------------------------------------------------------------------
    group('initiatePayment', () {
      test('sets state to processing on success', () async {
        mockRepo.initiatePaymentResult = const PaymentResult(
          transactionId: 'txn-123',
          status: PaymentStatus.pending,
        );

        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        await notifier.initiatePayment(makePaymentRequest());

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.processing);
      });

      test('stores the transaction ID on success', () async {
        mockRepo.initiatePaymentResult = const PaymentResult(
          transactionId: 'txn-456',
          status: PaymentStatus.pending,
        );

        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        await notifier.initiatePayment(makePaymentRequest());

        expect(notifier.currentTransactionId, 'txn-456');
      });

      test('sets state to failed on error', () async {
        mockRepo.initiatePaymentError = Exception('Network error');

        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        await notifier.initiatePayment(makePaymentRequest());

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.failed);
      });

      test('starts watching the transaction after success', () async {
        mockRepo.initiatePaymentResult = const PaymentResult(
          transactionId: 'txn-789',
          status: PaymentStatus.pending,
        );

        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        await notifier.initiatePayment(makePaymentRequest());

        // Emit a success event on the stream — should update state.
        mockRepo.transactionStreamController!.add(
          makeTransaction(id: 'txn-789', status: PaymentStatus.success),
        );

        // Allow the stream event to propagate.
        await Future<void>.delayed(Duration.zero);

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.success);
      });
    });

    // -----------------------------------------------------------------------
    // 3. cancelPayment
    // -----------------------------------------------------------------------
    group('cancelPayment', () {
      test('sets state to cancelled on success', () async {
        mockRepo.initiatePaymentResult = const PaymentResult(
          transactionId: 'txn-cancel',
          status: PaymentStatus.pending,
        );

        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // First initiate a payment.
        await notifier.initiatePayment(makePaymentRequest());
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );

        // Now cancel it.
        await notifier.cancelPayment('txn-cancel');

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.cancelled);
      });

      test('handles errors gracefully (state becomes AsyncError)', () async {
        mockRepo.cancelPaymentError = Exception('Cancel failed');

        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        await notifier.cancelPayment('txn-error');

        // On error, state should be an AsyncError.
        final asyncState = container.read(paymentNotifierProvider);
        expect(asyncState.hasError, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 4. watchTransaction — status mapping
    // -----------------------------------------------------------------------
    group('watchTransaction', () {
      setUp(() async {
        mockRepo.initiatePaymentResult = const PaymentResult(
          transactionId: 'txn-watch',
          status: PaymentStatus.pending,
        );
        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);
        await notifier.initiatePayment(makePaymentRequest());
      });

      test('maps PaymentStatus.pending to PaymentUIState.processing',
          () async {
        mockRepo.transactionStreamController!.add(
          makeTransaction(status: PaymentStatus.pending),
        );
        await Future<void>.delayed(Duration.zero);

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.processing);
      });

      test('maps PaymentStatus.processing to PaymentUIState.processing',
          () async {
        mockRepo.transactionStreamController!.add(
          makeTransaction(status: PaymentStatus.processing),
        );
        await Future<void>.delayed(Duration.zero);

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.processing);
      });

      test('maps PaymentStatus.success to PaymentUIState.success', () async {
        mockRepo.transactionStreamController!.add(
          makeTransaction(status: PaymentStatus.success),
        );
        await Future<void>.delayed(Duration.zero);

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.success);
      });

      test('maps PaymentStatus.failed to PaymentUIState.failed', () async {
        mockRepo.transactionStreamController!.add(
          makeTransaction(status: PaymentStatus.failed),
        );
        await Future<void>.delayed(Duration.zero);

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.failed);
      });

      test('maps PaymentStatus.cancelled to PaymentUIState.cancelled',
          () async {
        mockRepo.transactionStreamController!.add(
          makeTransaction(status: PaymentStatus.cancelled),
        );
        await Future<void>.delayed(Duration.zero);

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.cancelled);
      });

      test(
          'auto-cancels subscription on terminal state (no further updates after success)',
          () async {
        // Emit success — terminal state.
        mockRepo.transactionStreamController!.add(
          makeTransaction(status: PaymentStatus.success),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );

        // Emit another event — should NOT change state since subscription
        // was cancelled.
        mockRepo.transactionStreamController!.add(
          makeTransaction(status: PaymentStatus.failed),
        );
        await Future<void>.delayed(Duration.zero);

        // State should still be success.
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.success,
        );
      });
    });

    // -----------------------------------------------------------------------
    // 5. 5-minute timeout
    // -----------------------------------------------------------------------
    group('5-minute timeout', () {
      test('timer fires and state becomes failed', () {
        fakeAsync((async) {
          final fakeRepo = MockPaymentRepository();
          fakeRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          fakeRepo.initiatePaymentResult = const PaymentResult(
            transactionId: 'txn-timeout',
            status: PaymentStatus.pending,
          );

          final fakeContainer = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(fakeRepo),
            ],
          );
          // Keep alive.
          fakeContainer.listen(paymentNotifierProvider, (_, __) {});

          final notifier =
              fakeContainer.read(paymentNotifierProvider.notifier);

          // Initiate payment (starts the timer).
          notifier.initiatePayment(makePaymentRequest());
          async.flushMicrotasks();

          expect(
            fakeContainer.read(paymentNotifierProvider).value,
            PaymentUIState.processing,
          );

          // Advance time by 5 minutes.
          async.elapse(const Duration(minutes: 5));

          expect(
            fakeContainer.read(paymentNotifierProvider).value,
            PaymentUIState.failed,
          );

          fakeContainer.dispose();
          fakeRepo.transactionStreamController?.close();
        });
      });

      test('timer is cancelled when terminal state is reached', () {
        fakeAsync((async) {
          final fakeRepo = MockPaymentRepository();
          fakeRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          fakeRepo.initiatePaymentResult = const PaymentResult(
            transactionId: 'txn-timer-cancel',
            status: PaymentStatus.pending,
          );

          final fakeContainer = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(fakeRepo),
            ],
          );
          fakeContainer.listen(paymentNotifierProvider, (_, __) {});

          final notifier =
              fakeContainer.read(paymentNotifierProvider.notifier);

          notifier.initiatePayment(makePaymentRequest());
          async.flushMicrotasks();

          // Emit success before timeout.
          fakeRepo.transactionStreamController!.add(
            makeTransaction(status: PaymentStatus.success),
          );
          async.flushMicrotasks();

          expect(
            fakeContainer.read(paymentNotifierProvider).value,
            PaymentUIState.success,
          );

          // Advance past the timeout — state should NOT change to failed.
          async.elapse(const Duration(minutes: 5));

          expect(
            fakeContainer.read(paymentNotifierProvider).value,
            PaymentUIState.success,
          );

          fakeContainer.dispose();
          fakeRepo.transactionStreamController?.close();
        });
      });

      test('timer is cancelled on cancelPayment', () {
        fakeAsync((async) {
          final fakeRepo = MockPaymentRepository();
          fakeRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          fakeRepo.initiatePaymentResult = const PaymentResult(
            transactionId: 'txn-cancel-timer',
            status: PaymentStatus.pending,
          );

          final fakeContainer = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(fakeRepo),
            ],
          );
          fakeContainer.listen(paymentNotifierProvider, (_, __) {});

          final notifier =
              fakeContainer.read(paymentNotifierProvider.notifier);

          notifier.initiatePayment(makePaymentRequest());
          async.flushMicrotasks();

          // Cancel the payment.
          notifier.cancelPayment('txn-cancel-timer');
          async.flushMicrotasks();

          expect(
            fakeContainer.read(paymentNotifierProvider).value,
            PaymentUIState.cancelled,
          );

          // Advance past the timeout — state should NOT change to failed.
          async.elapse(const Duration(minutes: 5));

          expect(
            fakeContainer.read(paymentNotifierProvider).value,
            PaymentUIState.cancelled,
          );

          fakeContainer.dispose();
          fakeRepo.transactionStreamController?.close();
        });
      });

      test('timer is cancelled on reset()', () {
        fakeAsync((async) {
          final fakeRepo = MockPaymentRepository();
          fakeRepo.transactionStreamController =
              StreamController<domain.Transaction>.broadcast();
          fakeRepo.initiatePaymentResult = const PaymentResult(
            transactionId: 'txn-reset-timer',
            status: PaymentStatus.pending,
          );

          final fakeContainer = ProviderContainer(
            overrides: [
              paymentRepositoryProvider.overrideWithValue(fakeRepo),
            ],
          );
          fakeContainer.listen(paymentNotifierProvider, (_, __) {});

          final notifier =
              fakeContainer.read(paymentNotifierProvider.notifier);

          notifier.initiatePayment(makePaymentRequest());
          async.flushMicrotasks();

          // Reset the notifier.
          notifier.reset();
          async.flushMicrotasks();

          expect(
            fakeContainer.read(paymentNotifierProvider).value,
            PaymentUIState.idle,
          );

          // Advance past the timeout — state should NOT change to failed.
          async.elapse(const Duration(minutes: 5));

          expect(
            fakeContainer.read(paymentNotifierProvider).value,
            PaymentUIState.idle,
          );

          fakeContainer.dispose();
          fakeRepo.transactionStreamController?.close();
        });
      });
    });

    // -----------------------------------------------------------------------
    // 6. reset
    // -----------------------------------------------------------------------
    group('reset', () {
      test('returns to idle state', () async {
        mockRepo.initiatePaymentResult = const PaymentResult(
          transactionId: 'txn-reset',
          status: PaymentStatus.pending,
        );

        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        // Move to processing state.
        await notifier.initiatePayment(makePaymentRequest());
        expect(
          container.read(paymentNotifierProvider).value,
          PaymentUIState.processing,
        );

        // Reset.
        notifier.reset();

        final state = container.read(paymentNotifierProvider).value;
        expect(state, PaymentUIState.idle);
      });

      test('clears the current transaction ID', () async {
        mockRepo.initiatePaymentResult = const PaymentResult(
          transactionId: 'txn-reset-id',
          status: PaymentStatus.pending,
        );

        await waitForBuild(container);
        final notifier = container.read(paymentNotifierProvider.notifier);

        await notifier.initiatePayment(makePaymentRequest());
        expect(notifier.currentTransactionId, 'txn-reset-id');

        notifier.reset();
        expect(notifier.currentTransactionId, isNull);
      });
    });
  });
}
