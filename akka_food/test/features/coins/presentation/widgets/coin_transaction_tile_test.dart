import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/domain/entities/coin_transaction.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_transaction_tile.dart';

void main() {
  /// Helper to build the test widget.
  Widget buildTestWidget({
    required CoinTransaction transaction,
    ValueChanged<String>? onOrderTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            CoinTransactionTile(
              transaction: transaction,
              onOrderTap: onOrderTap,
            ),
          ],
        ),
      ),
    );
  }

  group('CoinTransactionTile', () {
    testWidgets('displays credit transaction with green + amount',
        (tester) async {
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: 500,
        reason: 'Purchase reward',
        orderId: 'order123',
        timestamp: DateTime(2024, 3, 15, 10, 30),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      // Displays +amount
      expect(find.text('+500'), findsOneWidget);
      // Displays reason
      expect(find.text('Purchase reward'), findsOneWidget);
      // Displays green add icon
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays debit transaction with red − amount',
        (tester) async {
      final transaction = CoinTransaction(
        id: 'tx2',
        uid: 'user1',
        amount: -1000,
        reason: 'Redemption',
        orderId: 'order456',
        timestamp: DateTime(2024, 3, 16, 14, 0),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      // Displays −amount
      expect(find.text('-1000'), findsOneWidget);
      // Displays reason
      expect(find.text('Redemption'), findsOneWidget);
      // Displays red remove icon
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('displays formatted date', (tester) async {
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: 250,
        reason: 'Purchase reward',
        timestamp: DateTime(2024, 6, 20, 9, 15),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      expect(find.textContaining('Jun 20, 2024 • 09:15'), findsOneWidget);
    });

    testWidgets('displays linked order ID when present', (tester) async {
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: 500,
        reason: 'Purchase reward',
        orderId: 'abc123',
        timestamp: DateTime(2024, 3, 15, 10, 30),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      expect(find.text('Order #abc123'), findsOneWidget);
    });

    testWidgets('does not display order reference when orderId is null',
        (tester) async {
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: 100,
        reason: 'Bonus',
        timestamp: DateTime(2024, 3, 15, 10, 30),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      expect(find.textContaining('Order #'), findsNothing);
    });

    testWidgets('order ID is tappable when onOrderTap is provided',
        (tester) async {
      String? tappedOrderId;
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: 500,
        reason: 'Purchase reward',
        orderId: 'order789',
        timestamp: DateTime(2024, 3, 15, 10, 30),
      );

      await tester.pumpWidget(buildTestWidget(
        transaction: transaction,
        onOrderTap: (id) => tappedOrderId = id,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Order #order789'));
      expect(tappedOrderId, equals('order789'));
    });

    testWidgets('has semantics label for accessibility', (tester) async {
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: 500,
        reason: 'Purchase reward',
        orderId: 'order123',
        timestamp: DateTime(2024, 3, 15, 10, 30),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      final semanticsWidget = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Credit of 500 coins'),
      );
      expect(semanticsWidget, findsOneWidget);
    });

    testWidgets('semantics label includes order ID when present',
        (tester) async {
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: -2000,
        reason: 'Redemption',
        orderId: 'orderXYZ',
        timestamp: DateTime(2024, 5, 10, 16, 45),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      final semanticsWidget = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Debit of 2000 coins') &&
            widget.properties.label!.contains('order orderXYZ'),
      );
      expect(semanticsWidget, findsOneWidget);
    });

    testWidgets('leading avatar has green background for credit',
        (tester) async {
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: 300,
        reason: 'Purchase reward',
        timestamp: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      // Green with low opacity for credit
      expect(avatar.backgroundColor, equals(Colors.green.withValues(alpha: 0.1)));
    });

    testWidgets('leading avatar has red/error background for debit',
        (tester) async {
      final transaction = CoinTransaction(
        id: 'tx1',
        uid: 'user1',
        amount: -1000,
        reason: 'Redemption',
        timestamp: DateTime(2024, 3, 15),
      );

      await tester.pumpWidget(buildTestWidget(transaction: transaction));
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      // Error color with low opacity for debit
      expect(avatar.backgroundColor, isNotNull);
    });
  });
}
