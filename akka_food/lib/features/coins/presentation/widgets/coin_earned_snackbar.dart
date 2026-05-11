import 'package:flutter/material.dart';

/// Shows a snackbar notification informing the user of coins earned.
///
/// Displays a celebratory message with a coin icon and the number of coins
/// earned. The snackbar auto-dismisses after 4 seconds.
///
/// Satisfies:
/// - Requirement 1 AC4: Display notification informing user of coins earned.
///
/// Usage:
/// ```dart
/// showCoinEarnedSnackbar(context, coinsEarned: 150);
/// ```
void showCoinEarnedSnackbar(BuildContext context, {required int coinsEarned}) {
  if (coinsEarned <= 0) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.monetization_on,
            color: Colors.amber[300],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '🎉 You earned $coinsEarned coins!',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}
