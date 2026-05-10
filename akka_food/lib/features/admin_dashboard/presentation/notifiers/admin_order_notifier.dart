import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/firestore_admin_order_data_source.dart';
import '../../data/repositories/admin_order_repository.dart';
import '../../domain/entities/admin_order_view.dart';
import '../../domain/repositories/i_admin_order_repository.dart';
import '../../domain/usecases/get_active_orders_use_case.dart';

part 'admin_order_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the [IAdminOrderRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
@riverpod
IAdminOrderRepository adminOrderRepository(Ref ref) {
  return AdminOrderRepository(FirestoreAdminOrderDataSource());
}

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Holds the UI state for the admin order list screen.
class AdminOrderState {
  const AdminOrderState({
    required this.allOrders,
    this.selectedStatus,
    this.dateRange,
    this.selectedDeliveryOption,
    this.searchQuery = '',
  });

  /// The full unfiltered list of active orders from Firestore.
  final List<AdminOrderView> allOrders;

  /// Filter: only show orders with this status. `null` means "all statuses".
  final DeliveryStatus? selectedStatus;

  /// Filter: only show orders whose [AdminOrderView.createdAt] falls within
  /// this range. `null` means "no date filter".
  final DateTimeRange? dateRange;

  /// Filter: only show orders with this delivery option. `null` means "all".
  final DeliveryOption? selectedDeliveryOption;

  /// Search query matched case-insensitively against order ID and customer name.
  /// Empty string means "no search filter".
  final String searchQuery;

  /// Returns the list of orders after applying all active filters.
  ///
  /// Satisfies Requirements 4.4 and 5.5.
  List<AdminOrderView> get filteredOrders {
    var orders = allOrders;

    if (selectedStatus != null) {
      orders = orders.where((o) => o.status == selectedStatus).toList();
    }

    if (dateRange != null) {
      final start = dateRange!.start;
      // Include the entire end day by advancing to midnight of the next day.
      final end = dateRange!.end.add(const Duration(days: 1));
      orders = orders
          .where((o) =>
              o.createdAt.isAfter(start) ||
              o.createdAt.isAtSameMomentAs(start))
          .where((o) => o.createdAt.isBefore(end))
          .toList();
    }

    if (selectedDeliveryOption != null) {
      orders = orders
          .where((o) => o.deliveryOption == selectedDeliveryOption)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      orders = orders
          .where((o) =>
              o.orderId.toLowerCase().contains(query) ||
              o.userDisplayName.toLowerCase().contains(query))
          .toList();
    }

    return orders;
  }

  AdminOrderState copyWith({
    List<AdminOrderView>? allOrders,
    Object? selectedStatus = _sentinel,
    Object? dateRange = _sentinel,
    Object? selectedDeliveryOption = _sentinel,
    String? searchQuery,
  }) {
    return AdminOrderState(
      allOrders: allOrders ?? this.allOrders,
      selectedStatus: selectedStatus == _sentinel
          ? this.selectedStatus
          : selectedStatus as DeliveryStatus?,
      dateRange:
          dateRange == _sentinel ? this.dateRange : dateRange as DateTimeRange?,
      selectedDeliveryOption: selectedDeliveryOption == _sentinel
          ? this.selectedDeliveryOption
          : selectedDeliveryOption as DeliveryOption?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Sentinel value to distinguish "not provided" from explicit null.
const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the state for [AdminOrderListScreen].
///
/// Listens to the real-time Firestore stream of active orders and exposes
/// filter controls for status, date range, and delivery option.
///
/// Satisfies Requirements 4.1 and 4.4.
@riverpod
class AdminOrderNotifier extends _$AdminOrderNotifier {
  StreamSubscription<List<AdminOrderView>>? _subscription;

  @override
  AsyncValue<AdminOrderState> build() {
    final repository = ref.watch(adminOrderRepositoryProvider);
    final useCase = GetActiveOrdersUseCase(repository);

    // Cancel any previous subscription when the notifier is rebuilt.
    ref.onDispose(() => _subscription?.cancel());

    // Start listening to the Firestore stream.
    _subscription = useCase().listen(
      (orders) {
        final current = state.valueOrNull;
        state = AsyncData(
          AdminOrderState(
            allOrders: orders,
            selectedStatus: current?.selectedStatus,
            dateRange: current?.dateRange,
            selectedDeliveryOption: current?.selectedDeliveryOption,
            searchQuery: current?.searchQuery ?? '',
          ),
        );
      },
      onError: (Object error, StackTrace stack) {
        state = AsyncError(error, stack);
      },
    );

    return const AsyncLoading();
  }

  // ---------------------------------------------------------------------------
  // Filter methods
  // ---------------------------------------------------------------------------

  /// Sets the status filter.
  ///
  /// Pass `null` to clear the filter and show all statuses.
  void setStatusFilter(DeliveryStatus? status) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedStatus: status));
  }

  /// Sets the date range filter.
  ///
  /// Pass `null` to clear the date range filter.
  void setDateRange(DateTimeRange? range) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(dateRange: range));
  }

  /// Sets the delivery option filter.
  ///
  /// Pass `null` to clear the filter and show all delivery options.
  void setDeliveryOptionFilter(DeliveryOption? option) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedDeliveryOption: option));
  }

  /// Sets the search query used to filter orders by order ID or customer name.
  ///
  /// Pass an empty string to clear the search filter.
  ///
  /// Satisfies Requirement 5.5.
  void setSearchQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: query));
  }

  /// Clears all active filters and the search query, restoring the full list.
  void clearFilters() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      AdminOrderState(allOrders: current.allOrders),
    );
  }
}
