import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/coin_transaction.dart';

/// A tile displaying a single [CoinTransaction] in the coin history list.
///
/// Shows:
/// - A leading icon/avatar indicating credit (green +) or debit (red −).
/// - The transaction reason (e.g. "Purchase reward", "Redemption").
/// - A formatted date/time string.
/// - The linked order ID (if present), tappable to navigate to order details.
/// - The +/− amount with color coding (green for credit, red for debit).
///
/// Includes [Semantics] for accessibility.
///
/// Satisfies Requirement 4 AC2: Each CoinTransaction displays amount (+/−),
/// reason, linked order ID, and timestamp.
class CoinTransactionTile extends StatelessWidget {
  const CoinTransactionTile({
    super.key,
    required this.transaction,
    this.onOrderTap,
  });

  /// The coin transaction to display.
  final CoinTransaction transaction;

  /// Optional callback when the linked order ID is tapped.
  /// Receives the order ID as a parameter.
  final ValueChanged<String>? onOrderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCredit = transaction.amount > 0;
    final amountText =
        isCredit ? '+${transaction.amount}' : '${transaction.amount}';
    final amountColor = isCredit ? Colors.green[700]! : colorScheme.error;
    final dateFormatted =
        DateFormat('MMM d, yyyy • HH:mm').format(transaction.timestamp);

    return Semantics(
      label: _buildSemanticsLabel(isCredit, dateFormatted),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? Colors.green.withValues(alpha: 0.1)
              : colorScheme.error.withValues(alpha: 0.1),
          child: Icon(
            isCredit ? Icons.add : Icons.remove,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Text(
          transaction.reason,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: _buildSubtitle(
          context,
          dateFormatted: dateFormatted,
          colorScheme: colorScheme,
          theme: theme,
        ),
        trailing: Text(
          amountText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ),
    );
  }

  /// Builds the subtitle containing the date and optional order ID.
  Widget _buildSubtitle(
    BuildContext context, {
    required String dateFormatted,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    if (transaction.orderId == null) {
      return Text(
        dateFormatted,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // When an order ID is present, show date + tappable order reference.
    return Row(
      children: [
        Flexible(
          child: Text(
            dateFormatted,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          ' • ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: onOrderTap != null
              ? () => onOrderTap!(transaction.orderId!)
              : null,
          child: Text(
            'Order #${transaction.orderId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onOrderTap != null
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              decoration:
                  onOrderTap != null ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a descriptive semantics label for screen readers.
  String _buildSemanticsLabel(bool isCredit, String dateFormatted) {
    final type = isCredit ? 'Credit' : 'Debit';
    final amount = transaction.amount.abs();
    final orderPart = transaction.orderId != null
        ? ', order ${transaction.orderId}'
        : '';
    return '$type of $amount coins, ${transaction.reason}$orderPart, $dateFormatted';
  }
}
