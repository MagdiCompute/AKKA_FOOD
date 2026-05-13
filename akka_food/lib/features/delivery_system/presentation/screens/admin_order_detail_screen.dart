import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/delivery_option.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/delivery_status_transitions.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../notifiers/delivery_tracking_notifier.dart';
import '../widgets/delivery_status_timeline.dart';

/// Admin screen that displays full order details and allows the admin to
/// update the delivery status.
///
/// Accepts an [orderId] parameter and watches the order in real-time using
/// [deliveryTrackingNotifierProvider].
///
/// Features:
/// - Full order details (items, totals, delivery info, current status)
/// - Status timeline with tracking updates
/// - Status update controls (next valid transitions as buttons)
/// - ETA input field when transitioning to outForDelivery
/// - Confirmation dialog before status updates
///
/// Satisfies Requirement 4 AC1, AC2, AC3, AC5.
class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  /// The ID of the order to display and manage.
  final String orderId;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  /// Whether a status update is currently in progress.
  bool _isUpdating = false;

  /// Controller for the ETA input field.
  final TextEditingController _etaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start watching the order for real-time updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(deliveryTrackingNotifierProvider.notifier)
          .watchOrder(widget.orderId);
    });
  }

  @override
  void dispose() {
    _etaController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(deliveryTrackingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: orderAsync.when(
        loading: _buildLoading,
        error: (error, _) {
          final lastKnown = ref
              .read(deliveryTrackingNotifierProvider.notifier)
              .lastKnownOrder;
          if (lastKnown != null) {
            return _buildContent(context, lastKnown);
          }
          return _buildError(context, error);
        },
        data: (order) {
          if (order == null) {
            return _buildLoading();
          }
          return _buildContent(context, order);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  Widget _buildLoading() {
    return Center(
      child: Semantics(
        label: 'Loading order details',
        child: const CircularProgressIndicator(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load order details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(deliveryTrackingNotifierProvider.notifier)
                    .watchOrder(widget.orderId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main content
  // ---------------------------------------------------------------------------

  Widget _buildContent(BuildContext context, Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Order header ───────────────────────────────────────────────
          _buildOrderHeader(context, order),
          const SizedBox(height: 16),

          // ── Status timeline ────────────────────────────────────────────
          DeliveryStatusTimeline(currentStatus: order.status),
          const SizedBox(height: 16),

          // ── Status update controls ─────────────────────────────────────
          _buildStatusUpdateControls(context, order),
          const SizedBox(height: 16),

          // ── Items list ─────────────────────────────────────────────────
          _buildItemsSection(context, order),
          const SizedBox(height: 16),

          // ── Order totals ───────────────────────────────────────────────
          _buildTotalsSection(context, order),
          const SizedBox(height: 16),

          // ── Delivery info ──────────────────────────────────────────────
          _buildDeliveryInfoSection(context, order),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Order header
  // ---------------------------------------------------------------------------

  Widget _buildOrderHeader(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Order ID: ${order.id}',
              child: Text(
                'Order #${order.id}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Semantics(
                    label: 'Customer ID: ${order.uid}',
                    child: Text(
                      'Customer: ${order.uid}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Semantics(
                  label: 'Created at ${_formatDateTime(order.createdAt)}',
                  child: Text(
                    'Created: ${_formatDateTime(order.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            if (order.deliveredAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Semantics(
                    label:
                        'Delivered at ${_formatDateTime(order.deliveredAt!)}',
                    child: Text(
                      'Delivered: ${_formatDateTime(order.deliveredAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status update controls
  // ---------------------------------------------------------------------------

  Widget _buildStatusUpdateControls(BuildContext context, Order order) {
    final nextStatuses = validStatusTransitions[order.status] ?? [];

    if (nextStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // ── ETA input (shown when outForDelivery is a valid next state) ──
            if (nextStatuses.contains(DeliveryStatus.outForDelivery))
              _buildEtaInput(context),

            // ── Status transition buttons ────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: nextStatuses.map((nextStatus) {
                return _StatusTransitionButton(
                  targetStatus: nextStatus,
                  isLoading: _isUpdating,
                  onPressed: () =>
                      _onStatusTransitionPressed(context, order, nextStatus),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ETA input field
  // ---------------------------------------------------------------------------

  Widget _buildEtaInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _etaController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          labelText: 'ETA (minutes) *',
          hintText: 'Enter estimated delivery time in minutes',
          helperText: 'Required — must be a positive number',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.timer_outlined),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status transition handler
  // ---------------------------------------------------------------------------

  Future<void> _onStatusTransitionPressed(
    BuildContext context,
    Order order,
    DeliveryStatus targetStatus,
  ) async {
    // Parse ETA if transitioning to outForDelivery.
    // ETA is required for outForDelivery transitions (Requirement 4 AC5).
    int? etaMinutes;
    if (targetStatus == DeliveryStatus.outForDelivery) {
      final etaText = _etaController.text.trim();
      if (etaText.isEmpty) {
        _showSnackBar('Please enter an ETA in minutes before marking as out for delivery.');
        return;
      }
      etaMinutes = int.tryParse(etaText);
      if (etaMinutes == null || etaMinutes <= 0) {
        _showSnackBar('ETA must be a positive number of minutes.');
        return;
      }
    }

    // Show confirmation dialog.
    final confirmed = await _showConfirmationDialog(
      context,
      order,
      targetStatus,
      etaMinutes,
    );

    if (confirmed != true || !mounted) return;

    await _updateOrderStatus(order.id, targetStatus, etaMinutes);
  }

  /// Shows a confirmation dialog before updating the order status.
  ///
  /// Satisfies Requirement 4 AC1 (persist new status).
  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    Order order,
    DeliveryStatus targetStatus,
    int? etaMinutes,
  ) {
    String message =
        'Update order status from "${order.status.label}" to "${targetStatus.label}"?';

    if (targetStatus == DeliveryStatus.outForDelivery && etaMinutes != null) {
      message += '\n\nETA: $etaMinutes minutes';
    }

    if (targetStatus == DeliveryStatus.delivered) {
      message += '\n\nThis will record the delivery timestamp.';
    }

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Status Update'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Calls the `adminUpdateOrderStatus` Cloud Function to update the order.
  ///
  /// Satisfies Requirement 4 AC1 (persist + TrackingUpdate),
  /// AC3 (delivery timestamp), AC5 (ETA on outForDelivery).
  Future<void> _updateOrderStatus(
    String orderId,
    DeliveryStatus newStatus,
    int? etaMinutes,
  ) async {
    setState(() => _isUpdating = true);

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('adminUpdateOrderStatus');

      final params = <String, dynamic>{
        'orderId': orderId,
        'newStatus': newStatus.toFirestoreString(),
      };

      if (etaMinutes != null) {
        params['etaMinutes'] = etaMinutes;
      }

      await callable.call(params);

      if (!mounted) return;

      _etaController.clear();
      _showSnackBar(
        'Status updated to "${newStatus.label}" successfully.',
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Failed to update status: ${e.message ?? e.code}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'An unexpected error occurred. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Items section
  // ---------------------------------------------------------------------------

  Widget _buildItemsSection(BuildContext context, Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${order.items.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => _buildItemRow(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, OrderItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        label:
            '${item.mealName}, quantity ${item.quantity}, '
            '${item.lineTotal.toStringAsFixed(0)} XOF',
        child: Row(
          children: [
            // Quantity badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${item.quantity}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Meal name
            Expanded(
              child: Text(
                item.mealName,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Line total
            Text(
              '${item.lineTotal.toStringAsFixed(0)} XOF',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Totals section
  // ---------------------------------------------------------------------------

  Widget _buildTotalsSection(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTotalRow(context, 'Subtotal', order.subtotal),
            _buildTotalRow(context, 'Delivery Fee', order.deliveryFee),
            if (order.discount > 0)
              _buildTotalRow(context, 'Discount', -order.discount),
            const Divider(height: 20),
            Semantics(
              label: 'Total: ${order.total.toStringAsFixed(0)} XOF',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${order.total.toStringAsFixed(0)} XOF',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, double amount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNegative = amount < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '${isNegative ? "-" : ""}${amount.abs().toStringAsFixed(0)} XOF',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isNegative ? Colors.green.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delivery info section
  // ---------------------------------------------------------------------------

  Widget _buildDeliveryInfoSection(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Delivery option
            _buildInfoRow(
              context,
              icon: Icons.local_shipping_outlined,
              label: 'Method',
              value: order.deliveryOption.label,
            ),

            // Delivery address (if delivery)
            if (order.deliveryOption == DeliveryOption.delivery &&
                order.deliveryAddress != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.location_on_outlined,
                label: 'Address',
                value:
                    '${order.deliveryAddress!.street}, ${order.deliveryAddress!.city}',
              ),
              if (order.deliveryAddress!.label != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    '(${order.deliveryAddress!.label})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ],

            // Pickup info
            if (order.deliveryOption == DeliveryOption.pickup) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.store_outlined,
                label: 'Pickup',
                value: 'Customer will pick up at restaurant',
              ),
            ],

            // ETA (if set)
            if (order.etaMinutes != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.timer_outlined,
                label: 'ETA',
                value: '${order.etaMinutes} minutes',
              ),
            ],

            // Failure reason (if failed)
            if (order.status == DeliveryStatus.failed &&
                order.failureReason != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: Icons.warning_amber_outlined,
                label: 'Failure Reason',
                value: order.failureReason!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '$label: $value',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
  }

  /// Formats a [DateTime] as "dd/MM/yyyy HH:mm".
  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

// ---------------------------------------------------------------------------
// _StatusTransitionButton
// ---------------------------------------------------------------------------

/// A button representing a valid status transition action.
///
/// Color-coded based on the target status:
/// - delivered: green (positive action)
/// - failed: red (destructive action)
/// - others: primary color
class _StatusTransitionButton extends StatelessWidget {
  const _StatusTransitionButton({
    required this.targetStatus,
    required this.isLoading,
    required this.onPressed,
  });

  final DeliveryStatus targetStatus;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (buttonStyle, icon) = _buttonConfig(context);

    return Semantics(
      label: 'Update status to ${targetStatus.label}',
      button: true,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text('Mark as ${targetStatus.label}'),
      ),
    );
  }

  (ButtonStyle?, IconData) _buttonConfig(BuildContext context) {
    switch (targetStatus) {
      case DeliveryStatus.delivered:
        return (
          FilledButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          Icons.check_circle_outline,
        );
      case DeliveryStatus.failed:
        return (
          FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          Icons.cancel_outlined,
        );
      case DeliveryStatus.confirmed:
        return (null, Icons.thumb_up_outlined);
      case DeliveryStatus.preparing:
        return (null, Icons.restaurant_outlined);
      case DeliveryStatus.outForDelivery:
        return (null, Icons.delivery_dining_outlined);
      case DeliveryStatus.readyForPickup:
        return (null, Icons.inventory_2_outlined);
      case DeliveryStatus.pending:
        return (null, Icons.receipt_long_outlined);
    }
  }
}
