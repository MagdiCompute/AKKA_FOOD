import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/admin_order_view.dart';
import '../../domain/usecases/update_order_status_use_case.dart';
import 'admin_order_notifier.dart';

part 'admin_order_detail_notifier.g.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Holds the UI state for [AdminOrderDetailScreen].
class AdminOrderDetailState {
  const AdminOrderDetailState({
    this.order,
    this.isUpdating = false,
    this.errorMessage,
  });

  /// The order being displayed. `null` while loading.
  final AdminOrderView? order;

  /// `true` while a status-update Cloud Function call is in flight.
  final bool isUpdating;

  /// Non-null when an error has occurred (load or update).
  final String? errorMessage;

  AdminOrderDetailState copyWith({
    AdminOrderView? order,
    bool? isUpdating,
    Object? errorMessage = _sentinel,
  }) {
    return AdminOrderDetailState(
      order: order ?? this.order,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages state for [AdminOrderDetailScreen].
///
/// Parameterized by [orderId] (family notifier).
///
/// On build, tries to find the order in the already-loaded
/// [adminOrderNotifierProvider] list to avoid an extra Firestore round-trip.
/// Falls back to fetching directly from the repository when not found.
///
/// Satisfies Requirements 4.2, 4.3, and 4.5.
@riverpod
class AdminOrderDetailNotifier extends _$AdminOrderDetailNotifier {
  @override
  AdminOrderDetailState build(String orderId) {
    // Try to find the order in the already-loaded active-orders list.
    final listState = ref.watch(adminOrderNotifierProvider).valueOrNull;
    final cached = listState?.allOrders
        .where((o) => o.orderId == orderId)
        .firstOrNull;

    if (cached != null) {
      return AdminOrderDetailState(order: cached);
    }

    // Not in the active list — fetch directly (e.g. delivered/cancelled order
    // opened via a deep link).
    _fetchOrder(orderId);
    return const AdminOrderDetailState();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _fetchOrder(String orderId) async {
    try {
      final repository = ref.read(adminOrderRepositoryProvider);
      final order = await repository.getOrderById(orderId);
      if (order == null) {
        state = state.copyWith(
          errorMessage: 'Order not found.',
        );
      } else {
        state = state.copyWith(order: order);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load order: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Updates the delivery status of the current order.
  ///
  /// [etaMinutes] is required when [status] is [DeliveryStatus.outForDelivery]
  /// (Requirement 4.5).
  ///
  /// On success, updates the local [order] copy optimistically.
  /// On failure, sets [errorMessage].
  Future<void> updateStatus(
    DeliveryStatus status, {
    int? etaMinutes,
  }) async {
    final currentOrder = state.order;
    if (currentOrder == null) return;

    state = state.copyWith(isUpdating: true, errorMessage: null);

    try {
      final repository = ref.read(adminOrderRepositoryProvider);
      final useCase = UpdateOrderStatusUseCase(repository);
      await useCase(currentOrder.orderId, status, etaMinutes: etaMinutes);

      // Optimistically update the local copy.
      state = state.copyWith(
        isUpdating: false,
        order: currentOrder.copyWith(
          status: status,
          etaMinutes: etaMinutes ?? currentOrder.etaMinutes,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: 'Failed to update status: $e',
      );
    }
  }

  /// Clears any current error message.
  void clearError() => state = state.copyWith(errorMessage: null);
}
