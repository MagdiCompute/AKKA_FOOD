import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/firestore_delivery_data_source.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/tracking_update.dart';
import '../../domain/repositories/i_delivery_repository.dart';

part 'delivery_tracking_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the [IDeliveryRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
@riverpod
IDeliveryRepository deliveryRepository(Ref ref) {
  return DeliveryRepository(
    FirestoreDeliveryDataSource(FirebaseFirestore.instance),
  );
}

// ---------------------------------------------------------------------------
// DeliveryTrackingNotifier
// ---------------------------------------------------------------------------

/// Manages real-time delivery tracking state for a single order.
///
/// Subscribes to the [IDeliveryRepository.watchOrder] stream and updates
/// the notifier state ([AsyncData], [AsyncLoading], [AsyncError]) based on
/// stream events.
///
/// When a stream error occurs after data has been received, the notifier
/// preserves the last known [Order] in [lastKnownOrder] so the UI can
/// display it alongside a "Reconnecting..." indicator.
///
/// Usage:
/// ```dart
/// final notifier = ref.read(deliveryTrackingNotifierProvider.notifier);
/// notifier.watchOrder('order_123');
/// ```
///
/// Satisfies Requirement 2 AC1, AC2.
@riverpod
class DeliveryTrackingNotifier extends _$DeliveryTrackingNotifier {
  /// Active subscription to the order document stream.
  StreamSubscription<Order>? _orderSubscription;

  /// The order ID currently being tracked.
  String? _currentOrderId;

  /// The last successfully received order data.
  ///
  /// Preserved when a stream error occurs so the UI can show the last known
  /// status with a "Reconnecting..." indicator instead of a full error state.
  Order? _lastKnownOrder;

  /// Exposes the currently tracked order ID.
  String? get currentOrderId => _currentOrderId;

  /// Exposes the last known order data, available even when state is
  /// [AsyncError]. Returns `null` if no data has been received yet.
  Order? get lastKnownOrder => _lastKnownOrder;

  @override
  FutureOr<Order?> build() {
    // Cancel any active subscription when the notifier is disposed/rebuilt.
    ref.onDispose(_dispose);
    return null;
  }

  // ---------------------------------------------------------------------------
  // watchOrder
  // ---------------------------------------------------------------------------

  /// Subscribes to real-time Firestore updates for [orderId].
  ///
  /// Cancels any existing subscription before starting a new one.
  /// Updates the notifier state as follows:
  /// - On new data → [AsyncData<Order?>] (also caches in [_lastKnownOrder])
  /// - On error → [AsyncError] (preserves [_lastKnownOrder] for UI fallback)
  ///
  /// Satisfies Requirement 2 AC1, AC2.
  void watchOrder(String orderId) {
    // Cancel any existing subscription before starting a new one.
    _disposeSubscription();

    _currentOrderId = orderId;
    _lastKnownOrder = null;
    state = const AsyncLoading();

    final repository = ref.read(deliveryRepositoryProvider);
    final stream = repository.watchOrder(orderId);

    _orderSubscription = stream.listen(
      (order) {
        _lastKnownOrder = order;
        state = AsyncData(order);
      },
      onError: (Object error, StackTrace stackTrace) {
        // Preserve _lastKnownOrder so the UI can show the last status
        // with a "Reconnecting..." indicator instead of a full error screen.
        state = AsyncError(error, stackTrace);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // stopWatching
  // ---------------------------------------------------------------------------

  /// Stops watching the current order and resets state to `null`.
  void stopWatching() {
    _disposeSubscription();
    _currentOrderId = null;
    _lastKnownOrder = null;
    state = const AsyncData(null);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _disposeSubscription() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  void _dispose() {
    _disposeSubscription();
  }
}

// ---------------------------------------------------------------------------
// TrackingUpdatesProvider
// ---------------------------------------------------------------------------

/// Provides a real-time stream of [TrackingUpdate]s for the given [orderId].
///
/// Returns an empty list while loading or if no updates exist yet.
/// Uses [IDeliveryRepository.watchTrackingUpdates] under the hood.
///
/// Satisfies Requirement 2 AC3 (timeline data).
@riverpod
Stream<List<TrackingUpdate>> trackingUpdates(Ref ref, String orderId) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return repository.watchTrackingUpdates(orderId);
}
