import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/cloud_function_payment_data_source.dart';
import '../../data/datasources/firestore_transaction_data_source.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/repositories/i_payment_repository.dart';

part 'payment_notifier.g.dart';

// ---------------------------------------------------------------------------
// PaymentUIState
// ---------------------------------------------------------------------------

/// UI state machine for the payment flow.
///
/// Drives screen transitions:
/// - [idle] — no active payment; default state
/// - [initiating] — payment request sent to Cloud Function
/// - [processing] — Orange Money USSD push sent; awaiting user confirmation
/// - [success] — payment confirmed by callback
/// - [failed] — payment failed or timed out
/// - [cancelled] — user cancelled the pending payment
enum PaymentUIState { idle, initiating, processing, success, failed, cancelled }

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [PaymentRepository] bound to [IPaymentRepository].
///
/// Wires up [CloudFunctionPaymentDataSource] and [FirestoreTransactionDataSource]
/// with their Firebase dependencies.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
IPaymentRepository paymentRepository(Ref ref) {
  return PaymentRepository(
    cloudFunctionDataSource: CloudFunctionPaymentDataSource(
      functions: FirebaseFunctions.instance,
    ),
    firestoreDataSource: FirestoreTransactionDataSource(
      firestore: FirebaseFirestore.instance,
    ),
    firebaseAuth: FirebaseAuth.instance,
  );
}

// ---------------------------------------------------------------------------
// PaymentNotifier
// ---------------------------------------------------------------------------

/// Manages the payment UI state machine via Riverpod.
///
/// Orchestrates:
/// - [initiatePayment] — starts a payment flow (Req 1 AC2)
/// - [cancelPayment] — cancels a pending payment (Req 4 AC1, AC2)
/// - [watchTransaction] — subscribes to Firestore real-time updates
///
/// The Firestore real-time listener on the transaction document drives
/// state transitions from [processing] → [success] / [failed].
///
/// A client-side timeout of 5 minutes acts as a fallback in case the
/// server-side `expireStaleTransactions` function hasn't run yet (Req 3 AC1).
@riverpod
class PaymentNotifier extends _$PaymentNotifier {
  /// Client-side payment timeout duration (matches server-side expiry).
  static const paymentTimeout = Duration(minutes: 5);

  /// The current transaction ID being tracked, if any.
  String? _currentTransactionId;

  /// Active subscription to the Firestore transaction stream.
  StreamSubscription<domain.Transaction>? _transactionSubscription;

  /// Timer for the client-side 5-minute payment timeout fallback.
  Timer? _timeoutTimer;

  /// Exposes the current transaction ID so the UI can reference it.
  String? get currentTransactionId => _currentTransactionId;

  @override
  FutureOr<PaymentUIState> build() {
    // Cancel any active subscription and timer when the notifier is disposed.
    ref.onDispose(_dispose);
    return PaymentUIState.idle;
  }

  // ---------------------------------------------------------------------------
  // initiatePayment
  // ---------------------------------------------------------------------------

  /// Initiates a payment with Orange Money Mali.
  ///
  /// Flow:
  /// 1. Sets state to [PaymentUIState.initiating]
  /// 2. Calls [IPaymentRepository.initiatePayment] via Cloud Function
  /// 3. Stores the returned transaction ID
  /// 4. Sets state to [PaymentUIState.processing]
  /// 5. Starts watching the transaction for real-time status updates
  ///
  /// On error, sets state to [PaymentUIState.failed].
  ///
  /// Satisfies Requirement 1 AC2.
  Future<void> initiatePayment(PaymentRequest request) async {
    state = const AsyncData(PaymentUIState.initiating);

    try {
      final repository = ref.read(paymentRepositoryProvider);
      final result = await repository.initiatePayment(request);

      _currentTransactionId = result.transactionId;
      state = const AsyncData(PaymentUIState.processing);

      // Start the 5-minute client-side timeout fallback (Req 3 AC1).
      _startTimeoutTimer();

      // Start listening to real-time transaction updates.
      watchTransaction(result.transactionId);
    } catch (e, st) {
      debugPrint('PaymentNotifier.initiatePayment error: $e');
      state = AsyncError(e, st);
      // Also set the data state to failed for UI convenience.
      state = const AsyncData(PaymentUIState.failed);
    }
  }

  // ---------------------------------------------------------------------------
  // cancelPayment
  // ---------------------------------------------------------------------------

  /// Cancels a pending payment before Orange Money confirms it.
  ///
  /// Flow:
  /// 1. Calls [IPaymentRepository.cancelPayment] via Cloud Function
  /// 2. Cancels the active Firestore subscription
  /// 3. Sets state to [PaymentUIState.cancelled]
  ///
  /// On error, the state remains unchanged and the error is logged.
  ///
  /// Satisfies Requirement 4 AC1, AC2.
  Future<void> cancelPayment(String transactionId) async {
    try {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.cancelPayment(transactionId);

      _dispose();
      _currentTransactionId = null;
      state = const AsyncData(PaymentUIState.cancelled);
    } catch (e, st) {
      debugPrint('PaymentNotifier.cancelPayment error: $e');
      state = AsyncError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // watchTransaction
  // ---------------------------------------------------------------------------

  /// Subscribes to real-time Firestore updates for [transactionId].
  ///
  /// Maps [PaymentStatus] from the transaction document to [PaymentUIState]:
  /// - `pending` / `processing` → [PaymentUIState.processing]
  /// - `success` → [PaymentUIState.success]
  /// - `failed` → [PaymentUIState.failed]
  /// - `cancelled` → [PaymentUIState.cancelled]
  /// - `refunded` → [PaymentUIState.failed] (edge case)
  ///
  /// The subscription is automatically cancelled when:
  /// - A terminal state is reached (success, failed, cancelled)
  /// - The notifier is disposed
  /// - [cancelPayment] is called
  void watchTransaction(String transactionId) {
    // Cancel any existing subscription before starting a new one.
    _disposeSubscription();

    final repository = ref.read(paymentRepositoryProvider);
    final stream = repository.watchTransaction(transactionId);

    _transactionSubscription = stream.listen(
      (transaction) {
        final uiState = _mapStatusToUIState(transaction.status);
        state = AsyncData(uiState);

        // Auto-cancel subscription and timer on terminal states.
        if (_isTerminalState(uiState)) {
          _cancelTimeoutTimer();
          _disposeSubscription();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('PaymentNotifier.watchTransaction error: $error');
        state = AsyncError(error, stackTrace);
        state = const AsyncData(PaymentUIState.failed);
        _cancelTimeoutTimer();
        _disposeSubscription();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // reset
  // ---------------------------------------------------------------------------

  /// Resets the notifier to [PaymentUIState.idle].
  ///
  /// Call this when navigating away from the payment flow or starting a new
  /// payment attempt after failure/cancellation.
  void reset() {
    _dispose();
    _currentTransactionId = null;
    state = const AsyncData(PaymentUIState.idle);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Maps a domain [PaymentStatus] to a [PaymentUIState].
  PaymentUIState _mapStatusToUIState(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return PaymentUIState.processing;
      case PaymentStatus.success:
        return PaymentUIState.success;
      case PaymentStatus.failed:
        return PaymentUIState.failed;
      case PaymentStatus.cancelled:
        return PaymentUIState.cancelled;
      case PaymentStatus.refunded:
        return PaymentUIState.failed;
    }
  }

  /// Returns `true` if [uiState] is a terminal state (no further transitions).
  bool _isTerminalState(PaymentUIState uiState) {
    return uiState == PaymentUIState.success ||
        uiState == PaymentUIState.failed ||
        uiState == PaymentUIState.cancelled;
  }

  /// Starts the client-side 5-minute timeout timer.
  ///
  /// If the timer fires before a terminal state is reached via the Firestore
  /// listener, the payment is considered timed out and state transitions to
  /// [PaymentUIState.failed]. The Firestore subscription is also cancelled.
  ///
  /// This is a fallback in case the server-side `expireStaleTransactions`
  /// scheduled function hasn't run yet or there's a network delay.
  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(paymentTimeout, _onTimeout);
  }

  /// Handles the timeout event: sets state to failed and cleans up.
  void _onTimeout() {
    debugPrint('PaymentNotifier: client-side payment timeout fired');
    _disposeSubscription();
    _timeoutTimer = null;
    state = const AsyncData(PaymentUIState.failed);
  }

  /// Cancels the timeout timer if active.
  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Cancels the active Firestore subscription and cleans up resources.
  void _disposeSubscription() {
    _transactionSubscription?.cancel();
    _transactionSubscription = null;
  }

  /// Disposes both the Firestore subscription and the timeout timer.
  void _dispose() {
    _disposeSubscription();
    _cancelTimeoutTimer();
  }
}
