import 'package:flutter/material.dart';

import '../../domain/entities/admin_order_view.dart';

/// A list tile that displays a single [AdminOrderView] in the admin order list.
///
/// Shows the order ID (truncated), user name, total (XOF), status badge,
/// delivery option, and creation time. Responds to taps for navigation to
/// the order detail screen.
class OrderListTile extends StatelessWidget {
  const OrderListTile({
    super.key,
    required this.order,
    required this.onTap,
  });

  final AdminOrderView order;

  /// Called when the tile is tapped (navigate to order detail).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: order ID + status badge ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${_truncateId(order.orderId)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 6),

              // ── User name ─────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.userDisplayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ── Bottom row: total + delivery option + time ────────────
              Row(
                children: [
                  // Total
                  Text(
                    '${order.total.toStringAsFixed(0)} XOF',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Delivery option chip
                  _DeliveryOptionChip(option: order.deliveryOption),

                  const Spacer(),

                  // Creation time
                  Text(
                    _formatTime(order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Truncates the order ID to the last 8 characters for compact display.
  String _truncateId(String id) {
    if (id.length <= 8) return id;
    return id.substring(id.length - 8);
  }

  /// Formats a [DateTime] as HH:mm or "Yesterday HH:mm" / "DD/MM HH:mm".
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(dt.year, dt.month, dt.day);
    final hhmm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (orderDay == today) {
      return hhmm;
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (orderDay == yesterday) {
      return 'Yesterday $hhmm';
    }

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} $hhmm';
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

/// A compact colored badge showing the order's [DeliveryStatus].
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = _colorsForStatus(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (Color, Color) _colorsForStatus(BuildContext context, DeliveryStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case DeliveryStatus.pending:
        return (colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant);
      case DeliveryStatus.confirmed:
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0));
      case DeliveryStatus.preparing:
        return (const Color(0xFFFFF3E0), const Color(0xFFE65100));
      case DeliveryStatus.readyForPickup:
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case DeliveryStatus.outForDelivery:
        return (const Color(0xFFEDE7F6), const Color(0xFF4527A0));
      case DeliveryStatus.delivered:
        return (colorScheme.primaryContainer, colorScheme.onPrimaryContainer);
      case DeliveryStatus.cancelled:
        return (colorScheme.errorContainer, colorScheme.onErrorContainer);
    }
  }
}

// ---------------------------------------------------------------------------
// Delivery option chip
// ---------------------------------------------------------------------------

/// A small chip showing the order's [DeliveryOption].
class _DeliveryOptionChip extends StatelessWidget {
  const _DeliveryOptionChip({required this.option});

  final DeliveryOption option;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = option == DeliveryOption.delivery
        ? Icons.delivery_dining_outlined
        : Icons.storefront_outlined;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          option.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
