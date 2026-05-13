import 'dart:async';

import 'package:flutter/material.dart';

/// Displays the estimated time of arrival with a live countdown timer.
///
/// Counts down in seconds, showing MM:SS format.
/// Hides itself when [etaMinutes] is null.
///
/// Satisfies Requirement 2 AC4.
class ETACard extends StatefulWidget {
  final int? etaMinutes;

  const ETACard({super.key, this.etaMinutes});

  @override
  State<ETACard> createState() => _ETACardState();
}

class _ETACardState extends State<ETACard> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = (widget.etaMinutes ?? 0) * 60;
    _startCountdown();
  }

  @override
  void didUpdateWidget(ETACard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.etaMinutes != oldWidget.etaMinutes) {
      _remainingSeconds = (widget.etaMinutes ?? 0) * 60;
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    if (_remainingSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
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

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.etaMinutes == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isLate = _remainingSeconds <= 0;
    final totalSeconds = (widget.etaMinutes ?? 1) * 60;
    final progress = totalSeconds > 0
        ? (1.0 - (_remainingSeconds / totalSeconds)).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      color: isLate
          ? colorScheme.errorContainer.withValues(alpha: 0.3)
          : colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Countdown circle
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor:
                        colorScheme.onSecondaryContainer.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isLate ? colorScheme.error : colorScheme.secondary,
                    ),
                  ),
                  Icon(
                    isLate ? Icons.timer_off : Icons.delivery_dining,
                    size: 24,
                    color: isLate ? colorScheme.error : colorScheme.secondary,
                  ),
                ],
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
                    isLate ? 'Votre commande arrive !' : _formatTime(_remainingSeconds),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: isLate
                              ? colorScheme.error
                              : colorScheme.onSecondaryContainer,
                        ),
                  ),
                  if (!isLate) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_remainingSeconds ~/ 60} min restantes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
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
