// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paymentRepositoryHash() => r'582a74c4e295f388a3319a36d6162980567e11a2';

/// Provides the concrete [PaymentRepository] bound to [IPaymentRepository].
///
/// Wires up [CloudFunctionPaymentDataSource] and [FirestoreTransactionDataSource]
/// with their Firebase dependencies.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [paymentRepository].
@ProviderFor(paymentRepository)
final paymentRepositoryProvider =
    AutoDisposeProvider<IPaymentRepository>.internal(
      paymentRepository,
      name: r'paymentRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paymentRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PaymentRepositoryRef = AutoDisposeProviderRef<IPaymentRepository>;
String _$paymentNotifierHash() => r'7f15db067dfc63271d60862c6fc1464c828f1221';

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
/// Copied from [PaymentNotifier].
@ProviderFor(PaymentNotifier)
final paymentNotifierProvider =
    AutoDisposeAsyncNotifierProvider<PaymentNotifier, PaymentUIState>.internal(
      PaymentNotifier.new,
      name: r'paymentNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paymentNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaymentNotifier = AutoDisposeAsyncNotifier<PaymentUIState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
