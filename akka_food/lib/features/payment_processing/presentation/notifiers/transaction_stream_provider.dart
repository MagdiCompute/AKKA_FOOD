import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/transaction.dart' as domain;
import 'payment_notifier.dart';

part 'transaction_stream_provider.g.dart';

// ---------------------------------------------------------------------------
// Transaction Stream Provider
// ---------------------------------------------------------------------------

/// A family [StreamProvider] that exposes a real-time [domain.Transaction]
/// stream for a given [transactionId].
///
/// The UI can watch this provider directly to reactively rebuild whenever
/// the Firestore transaction document changes (e.g., status transitions
/// from `pending` → `processing` → `success`).
///
/// Usage in a widget:
/// ```dart
/// final asyncTransaction = ref.watch(transactionStreamProvider(transactionId));
/// asyncTransaction.when(
///   data: (transaction) => Text(transaction.status.name),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
///
/// This provider is auto-disposed when no longer watched, which automatically
/// cancels the underlying Firestore snapshot listener.
@riverpod
Stream<domain.Transaction> transactionStream(
  Ref ref,
  String transactionId,
) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.watchTransaction(transactionId);
}
