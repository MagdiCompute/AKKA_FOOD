import 'package:flutter/material.dart';

/// Displays the estimated time of arrival when the order is out for delivery.
///
/// Hides itself (returns [SizedBox.shrink]) when [etaMinutes] is null,
/// per design: "ETA not set → Hide ETA card until admin sets it."
///
/// Shows a clock icon and the ETA in minutes prominently.
///
/// Satisfies Requirement 2 AC4.
class ETACard extends StatelessWidget {
  /// Estimated time of arrival in minutes; may be null if not yet set by admin.
  final int? etaMinutes;

  const ETACard({
    super.key,
    this.etaMinutes,
  });

  @override
  Widget build(BuildContext context) {
    // Hide the card if ETA is not set (per design: "ETA not set → Hide ETA card").
    if (etaMinutes == null) return const SizedBox.shrink();

    return Semantics(
      label: 'Estimated delivery time: $etaMinutes minutes',
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.access_time_filled,
                size: 40,
                color: Theme.of(context).colorScheme.secondary,
                semanticLabel: 'Clock icon',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Arrival',
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$etaMinutes minutes',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
