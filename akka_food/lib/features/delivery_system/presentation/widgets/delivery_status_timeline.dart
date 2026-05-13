import 'package:flutter/material.dart';

import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/tracking_update.dart';

/// A polished vertical timeline widget displaying all delivery status stages.
///
/// Highlights the current stage, marks past stages as completed (with checkmark),
/// and greys out future stages. Optionally shows timestamps from tracking updates.
///
/// The stages shown depend on [isPickup]:
/// - Pickup: pending → confirmed → preparing → readyForPickup → delivered
/// - Delivery: pending → confirmed → preparing → outForDelivery → delivered
///
/// Satisfies Requirement 2 AC3.
class DeliveryStatusTimeline extends StatelessWidget {
  /// The current delivery status to highlight in the timeline.
  final DeliveryStatus currentStatus;

  /// Whether this order is a pickup (true) or delivery (false).
  final bool isPickup;

  /// Optional list of tracking updates to display timestamps for each stage.
  final List<TrackingUpdate>? trackingUpdates;

  const DeliveryStatusTimeline({
    super.key,
    required this.currentStatus,
    this.isPickup = false,
    this.trackingUpdates,
  });

  /// Returns the stages based on the delivery option.
  List<DeliveryStatus> get stages {
    if (isPickup) {
      return const [
        DeliveryStatus.pending,
        DeliveryStatus.confirmed,
        DeliveryStatus.preparing,
        DeliveryStatus.readyForPickup,
        DeliveryStatus.delivered,
      ];
    } else {
      return const [
        DeliveryStatus.pending,
        DeliveryStatus.confirmed,
        DeliveryStatus.preparing,
        DeliveryStatus.outForDelivery,
        DeliveryStatus.delivered,
      ];
    }
  }

  /// Returns the appropriate icon for each delivery stage.
  static IconData _iconForStage(DeliveryStatus stage) {
    switch (stage) {
      case DeliveryStatus.pending:
        return Icons.receipt_long;
      case DeliveryStatus.confirmed:
        return Icons.check_circle;
      case DeliveryStatus.preparing:
        return Icons.restaurant;
      case DeliveryStatus.readyForPickup:
        return Icons.inventory_2;
      case DeliveryStatus.outForDelivery:
        return Icons.delivery_dining;
      case DeliveryStatus.delivered:
        return Icons.home;
      case DeliveryStatus.failed:
        return Icons.error_outline;
    }
  }

  /// Finds the timestamp for a given stage from tracking updates.
  DateTime? _timestampForStage(DeliveryStatus stage) {
    if (trackingUpdates == null || trackingUpdates!.isEmpty) return null;
    try {
      return trackingUpdates!
          .firstWhere((update) => update.status == stage)
          .timestamp;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentIndex = stages.indexOf(currentStatus);
    
    // Fallback: if currentStatus isn't in stages (e.g., readyForPickup on a
    // delivery order), map it to the closest equivalent stage.
    if (currentIndex < 0) {
      if (currentStatus == DeliveryStatus.readyForPickup) {
        // readyForPickup is equivalent to the stage after preparing
        currentIndex = stages.indexOf(DeliveryStatus.preparing) + 1;
        if (currentIndex >= stages.length) currentIndex = stages.length - 1;
      } else if (currentStatus == DeliveryStatus.outForDelivery) {
        currentIndex = stages.indexOf(DeliveryStatus.preparing) + 1;
        if (currentIndex >= stages.length) currentIndex = stages.length - 1;
      }
    }

    return Semantics(
      label: 'Delivery status timeline. Current status: ${currentStatus.label}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suivi de la commande',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...List.generate(stages.length, (index) {
                final stage = stages[index];
                final isPast = currentIndex >= 0 && index < currentIndex;
                final isCurrent = index == currentIndex;

                return _TimelineStageItem(
                  stage: stage,
                  icon: _iconForStage(stage),
                  isPast: isPast,
                  isCurrent: isCurrent,
                  isLast: index == stages.length - 1,
                  timestamp: _timestampForStage(stage),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single stage item in the vertical timeline.
class _TimelineStageItem extends StatelessWidget {
  final DeliveryStatus stage;
  final IconData icon;
  final bool isPast;
  final bool isCurrent;
  final bool isLast;
  final DateTime? timestamp;

  const _TimelineStageItem({
    required this.stage,
    required this.icon,
    required this.isPast,
    required this.isCurrent,
    required this.isLast,
    this.timestamp,
  });

  bool get isFuture => !isPast && !isCurrent;

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine colors based on stage state.
    final Color iconBgColor;
    final Color iconColor;
    final Color lineColor;
    final TextStyle? labelStyle;

    if (isCurrent) {
      iconBgColor = colorScheme.primary;
      iconColor = colorScheme.onPrimary;
      lineColor = colorScheme.outlineVariant;
      labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          );
    } else if (isPast) {
      iconBgColor = colorScheme.primary.withValues(alpha: 0.7);
      iconColor = colorScheme.onPrimary;
      lineColor = colorScheme.primary.withValues(alpha: 0.7);
      labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          );
    } else {
      // Future stage
      iconBgColor = colorScheme.surfaceContainerHighest;
      iconColor = colorScheme.outline;
      lineColor = colorScheme.outlineVariant;
      labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          );
    }

    final String semanticDescription;
    if (isCurrent) {
      semanticDescription = '${stage.label}, current stage';
    } else if (isPast) {
      semanticDescription = '${stage.label}, completed';
    } else {
      semanticDescription = '${stage.label}, upcoming';
    }

    return Semantics(
      label: semanticDescription,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Timeline indicator column ──────────────────────────────────
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Stage icon circle
                  Container(
                    width: isCurrent ? 36 : 32,
                    height: isCurrent ? 36 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isPast || isCurrent) ? iconBgColor : null,
                      border: isFuture
                          ? Border.all(color: colorScheme.outlineVariant, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isPast
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: iconColor,
                            )
                          : Icon(
                              icon,
                              size: isCurrent ? 20 : 16,
                              color: (isPast || isCurrent)
                                  ? iconColor
                                  : iconColor,
                            ),
                    ),
                  ),
                  // Connecting line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: lineColor,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Stage label and timestamp ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Vertically center label with the icon
                    SizedBox(
                      height: isCurrent ? 36 : 32,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          stage.label,
                          style: labelStyle,
                        ),
                      ),
                    ),
                    // Timestamp (if available)
                    if (timestamp != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(timestamp!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
