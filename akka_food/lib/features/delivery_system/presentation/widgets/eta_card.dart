import 'dart:async';

import 'package:flutter/material.dart';

/// Displays the estimated time of arrival with a live countdown timer.
///
/// Hides itself (returns [SizedBox.shrink]) when [etaMinutes] is null.
/// Shows a countdown that decrements every minute from the initial ETA.
///
/// Satisfies Requirement 2 AC4.
class ETACard extends StatefulWidget {
  /// Estimated time of arrival in minutes; may be null if not yet set by admin.
  final int? etaMinutes;

  const ETACard({super.key, this.etaMinutes});

  @override
  State<ETACard> createState() => _ETACardState();
}

class _ETACardState extends State<ETACard> {
  Timer? _timer;
  late int _remainingMinutes;

  @override
  void initState() {
    super.initState();
    _remainingMinutes = widget.etaMinutes ?? 0;
    _startCountdown();
  }

  @override
  void didUpdateWidget(ETACard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.etaMinutes != oldWidget.etaMinutes) {
      _remainingMinutes = widget.etaMinutes ?? 0;
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    if (_remainingMinutes <= 0) return;

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingMinutes--;
        if (_remainingMinutes <= 0) {
          _remainingMinutes = 0;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.etaMinutes == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isLate = _remainingMinutes <= 0;

    return Card(
      color: isLate
          ? colorScheme.errorContainer.withValues(alpha: 0.3)
          : colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Animated clock icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: child,
                );
              },
              child: Icon(
                isLate ? Icons.timer_off : Icons.access_time_filled,
                size: 40,
                color: isLate ? colorScheme.error : colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLate ? 'Arrivée imminente' : 'Temps estimé',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLate
                        ? 'Votre commande arrive !'
                        : '$_remainingMinutes min restantes',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isLate
                                  ? colorScheme.error
                                  : colorScheme.onSecondaryContainer,
                            ),
                  ),
                  if (!isLate) ...[
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 1.0 -
                            (_remainingMinutes / (widget.etaMinutes ?? 1)),
                        backgroundColor:
                            colorScheme.onSecondaryContainer.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.secondary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
