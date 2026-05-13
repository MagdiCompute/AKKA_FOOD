import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_order_view.dart';
import '../notifiers/admin_order_detail_notifier.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Formats [amount] as a whole-number string with narrow no-break space
/// thousands separators. e.g. 12500.0 → "12 500"
String _formatXof(double amount) {
  final intAmount = amount.round();
  final s = intAmount.toString();
  final buffer = StringBuffer();
  final offset = s.length % 3;
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (i - offset) % 3 == 0) buffer.write('\u202f');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

/// Displays full details for a single order and provides status-update controls.
///
/// Satisfies Requirements 4.2, 4.3, and 4.5.
class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState =
        ref.watch(adminOrderDetailNotifierProvider(orderId));

    // Show error snackbar when errorMessage changes.
    ref.listen<AdminOrderDetailState>(
      adminOrderDetailNotifierProvider(orderId),
      (previous, next) {
        if (next.errorMessage != null &&
            next.errorMessage != previous?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: () => ref
                    .read(adminOrderDetailNotifierProvider(orderId).notifier)
                    .clearError(),
              ),
            ),
          );
        }
      },
    );

    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$shortId'),
      ),
      body: _buildBody(context, detailState),
    );
  }

  Widget _buildBody(BuildContext context, AdminOrderDetailState state) {
    if (state.order == null && state.errorMessage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.order == null && state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      );
    }

    final order = state.order!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order items ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Items',
            child: Column(
              children: [
                ...order.items.map((item) => _OrderItemRow(item: item)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Order summary ───────────────────────────────────────────────
          _SectionCard(
            title: 'Summary',
            child: _OrderSummary(order: order),
          ),
          const SizedBox(height: 12),

          // ── Customer info ───────────────────────────────────────────────
          _SectionCard(
            title: 'Customer',
            child: _CustomerInfo(order: order),
          ),
          const SizedBox(height: 12),

          // ── Delivery info ───────────────────────────────────────────────
          _SectionCard(
            title: 'Delivery',
            child: _DeliveryInfo(order: order),
          ),
          const SizedBox(height: 12),

          // ── Current status ──────────────────────────────────────────────
          _SectionCard(
            title: 'Status',
            child: _StatusBadge(status: order.status),
          ),
          const SizedBox(height: 12),

          // ── Status update controls ──────────────────────────────────────
          _SectionCard(
            title: 'Update Status',
            child: _StatusUpdateControls(
              orderId: orderId,
              order: order,
              isUpdating: state.isUpdating,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order item row
// ---------------------------------------------------------------------------

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Quantity badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}×',
              style: textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Meal name
          Expanded(
            child: Text(item.mealName, style: textTheme.bodyMedium),
          ),
          // Unit price
          Text(
            '${_formatXof(item.unitPrice)} XOF',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          // Line total
          SizedBox(
            width: 90,
            child: Text(
              '${_formatXof(item.lineTotal)} XOF',
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order summary
// ---------------------------------------------------------------------------

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order});

  final AdminOrderView order;

  @override
  Widget build(BuildContext context) {
    final subtotal =
        order.items.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return Column(
      children: [
        _SummaryRow(
          label: 'Subtotal',
          value: '${_formatXof(subtotal)} XOF',
        ),
        const Divider(height: 16),
        _SummaryRow(
          label: 'Total',
          value: '${_formatXof(order.total)} XOF',
          bold: true,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Customer info
// ---------------------------------------------------------------------------

class _CustomerInfo extends StatelessWidget {
  const _CustomerInfo({required this.order});

  final AdminOrderView order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.person_outline,
          label: 'Name',
          value: order.userDisplayName,
        ),
        if (order.userPhone != null) ...[
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: order.userPhone!,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery info
// ---------------------------------------------------------------------------

class _DeliveryInfo extends StatelessWidget {
  const _DeliveryInfo({required this.order});

  final AdminOrderView order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: order.deliveryOption == DeliveryOption.delivery
              ? Icons.delivery_dining_outlined
              : Icons.storefront_outlined,
          label: 'Option',
          value: order.deliveryOption.label,
        ),
        if (order.deliveryOption == DeliveryOption.delivery &&
            order.deliveryAddress != null) ...[
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _formatAddress(order.deliveryAddress!),
          ),
        ],
        if (order.etaMinutes != null) ...[
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.timer_outlined,
            label: 'ETA',
            value: '${order.etaMinutes} min',
          ),
        ],
      ],
    );
  }

  String _formatAddress(DeliveryAddress address) {
    final parts = [address.street, address.city];
    if (address.additionalInfo != null &&
        address.additionalInfo!.isNotEmpty) {
      parts.add(address.additionalInfo!);
    }
    return parts.join(', ');
  }
}

// ---------------------------------------------------------------------------
// Info row
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsForStatus(context, status);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  (Color, Color) _colorsForStatus(
      BuildContext context, DeliveryStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case DeliveryStatus.pending:
        return (colorScheme.surfaceContainerHighest, colorScheme.onSurface);
      case DeliveryStatus.confirmed:
        return (Colors.blue.shade100, Colors.blue.shade800);
      case DeliveryStatus.preparing:
        return (Colors.orange.shade100, Colors.orange.shade800);
      case DeliveryStatus.readyForPickup:
        return (Colors.purple.shade100, Colors.purple.shade800);
      case DeliveryStatus.outForDelivery:
        return (Colors.teal.shade100, Colors.teal.shade800);
      case DeliveryStatus.delivered:
        return (Colors.green.shade100, Colors.green.shade800);
      case DeliveryStatus.cancelled:
        return (colorScheme.errorContainer, colorScheme.onErrorContainer);
    }
  }
}

// ---------------------------------------------------------------------------
// Status transition map
// ---------------------------------------------------------------------------

/// Returns the valid next statuses for a given [current] status and [deliveryOption].
///
/// - Pickup orders: preparing → readyForPickup → delivered
/// - Delivery orders: preparing → outForDelivery → delivered
///
/// Encodes the business rules from Requirements 4.3 and 4.5.
List<DeliveryStatus> _validNextStatuses(
  DeliveryStatus current, {
  DeliveryOption deliveryOption = DeliveryOption.delivery,
}) {
  final isPickup = deliveryOption == DeliveryOption.pickup;

  switch (current) {
    case DeliveryStatus.pending:
      return [DeliveryStatus.confirmed, DeliveryStatus.cancelled];
    case DeliveryStatus.confirmed:
      return [DeliveryStatus.preparing, DeliveryStatus.cancelled];
    case DeliveryStatus.preparing:
      if (isPickup) {
        return [DeliveryStatus.readyForPickup, DeliveryStatus.cancelled];
      } else {
        return [DeliveryStatus.outForDelivery, DeliveryStatus.cancelled];
      }
    case DeliveryStatus.readyForPickup:
      return [DeliveryStatus.delivered, DeliveryStatus.cancelled];
    case DeliveryStatus.outForDelivery:
      return [DeliveryStatus.delivered, DeliveryStatus.cancelled];
    case DeliveryStatus.delivered:
    case DeliveryStatus.cancelled:
      return [];
  }
}

// ---------------------------------------------------------------------------
// Status update controls widget
// ---------------------------------------------------------------------------

/// Displays valid next-status options and an ETA input when needed.
///
/// Satisfies Requirements 4.3 and 4.5.
class _StatusUpdateControls extends ConsumerStatefulWidget {
  const _StatusUpdateControls({
    required this.orderId,
    required this.order,
    required this.isUpdating,
  });

  final String orderId;
  final AdminOrderView order;
  final bool isUpdating;

  @override
  ConsumerState<_StatusUpdateControls> createState() =>
      _StatusUpdateControlsState();
}

class _StatusUpdateControlsState
    extends ConsumerState<_StatusUpdateControls> {
  DeliveryStatus? _selectedStatus;
  final _etaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void didUpdateWidget(_StatusUpdateControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selection when the underlying order status changes (e.g. after a
    // successful update the notifier updates the order optimistically).
    if (oldWidget.order.status != widget.order.status) {
      _selectedStatus = null;
      _etaController.clear();
      _phoneController.clear();
    }
  }

  @override
  void dispose() {
    _etaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _needsEta => _selectedStatus == DeliveryStatus.outForDelivery;
  bool get _needsPhone => _selectedStatus == DeliveryStatus.outForDelivery;

  Future<void> _submit() async {
    if (_selectedStatus == null) return;
    if (_needsEta && !(_formKey.currentState?.validate() ?? false)) return;

    final etaMinutes =
        _needsEta ? int.tryParse(_etaController.text.trim()) : null;
    final deliveryPhone =
        _needsPhone ? _phoneController.text.trim() : null;

    await ref
        .read(adminOrderDetailNotifierProvider(widget.orderId).notifier)
        .updateStatus(_selectedStatus!, etaMinutes: etaMinutes);

    // Save delivery phone number directly to Firestore
    if (deliveryPhone != null && deliveryPhone.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({'deliveryPhone': deliveryPhone});
      } catch (_) {}
    }

    // Show success snackbar only if still mounted and no error was set.
    if (!mounted) return;
    final newState =
        ref.read(adminOrderDetailNotifierProvider(widget.orderId));
    if (newState.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_selectedStatus!.label}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextStatuses = _validNextStatuses(
      widget.order.status,
      deliveryOption: widget.order.deliveryOption,
    );
    final disabled = widget.isUpdating;

    if (nextStatuses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No further status updates available.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status chips ───────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nextStatuses.map((status) {
              final selected = _selectedStatus == status;
              return FilterChip(
                label: Text(status.label),
                selected: selected,
                onSelected: disabled
                    ? null
                    : (value) {
                        setState(() {
                          _selectedStatus = value ? status : null;
                          if (_selectedStatus != DeliveryStatus.outForDelivery) {
                            _etaController.clear();
                          }
                        });
                      },
              );
            }).toList(),
          ),

          // ── ETA input (only when outForDelivery is selected) ───────────
          if (_needsEta) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _etaController,
              enabled: !disabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'ETA (minutes)',
                hintText: 'e.g. 30',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'ETA is required for out-for-delivery status';
                }
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'ETA must be a positive number';
                }
                return null;
              },
            ),
          ],

          // ── Delivery phone input (when outForDelivery is selected) ─────
          if (_needsPhone) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              enabled: !disabled,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro du livreur',
                hintText: '+223 76 XX XX XX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Submit button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (disabled || _selectedStatus == null) ? null : _submit,
              child: disabled
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Status'),
            ),
          ),
        ],
      ),
    );
  }
}
