import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/payment_processing/presentation/screens/order_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test data
  // ---------------------------------------------------------------------------

  final testItems = [
    const CartItem(
      mealId: 'meal-1',
      mealName: 'Poulet Yassa',
      mealImageUrl: 'https://example.com/yassa.jpg',
      unitPrice: 2500,
      quantity: 2,
      isAvailable: true,
    ),
    const CartItem(
      mealId: 'meal-2',
      mealName: 'Riz au Gras',
      mealImageUrl: 'https://example.com/riz.jpg',
      unitPrice: 1500,
      quantity: 1,
      isAvailable: true,
    ),
  ];

  final testData = OrderConfirmationData(
    orderId: 'abc12345xyz',
    items: testItems,
    totalPaid: 6500,
  );

  // ---------------------------------------------------------------------------
  // Helper to pump the screen with GoRouter
  // ---------------------------------------------------------------------------

  Widget buildTestWidget({OrderConfirmationData? data}) {
    final router = GoRouter(
      initialLocation: '/payment/confirmation',
      routes: [
        GoRoute(
          path: '/payment/confirmation',
          builder: (context, state) => const OrderConfirmationScreen(),
          // Pass data via extra
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: '/profile/orders/:orderId',
          builder: (context, state) =>
              Scaffold(body: Text('Order ${state.pathParameters['orderId']}')),
        ),
      ],
      initialExtra: data,
    );

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('OrderConfirmationScreen', () {
    testWidgets('displays success indicator and celebratory message',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      // Success checkmark icon
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Celebratory message
      expect(find.text('Order Confirmed! 🎉'), findsOneWidget);
      expect(
        find.text(
            'Your payment was successful and your order is being prepared.'),
        findsOneWidget,
      );
    });

    testWidgets('displays order ID (first 8 characters)', (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      // Order ID should show first 8 chars uppercased
      expect(find.text('Order #ABC12345'), findsOneWidget);
    });

    testWidgets('displays items list with quantities and prices',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      // Item names
      expect(find.text('Poulet Yassa'), findsOneWidget);
      expect(find.text('Riz au Gras'), findsOneWidget);

      // Quantities
      expect(find.text('×2'), findsOneWidget);
      expect(find.text('×1'), findsOneWidget);

      // Line totals
      expect(find.text('5,000 XOF'), findsOneWidget); // 2500 * 2
      expect(find.text('1,500 XOF'), findsOneWidget); // 1500 * 1
    });

    testWidgets('displays total paid in XOF format', (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      // Total paid
      expect(find.text('6,500 XOF'), findsOneWidget);
      expect(find.text('Total Paid'), findsOneWidget);
    });

    testWidgets('displays coins earned (5% of total)', (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      // 5% of 6500 = 325 coins
      expect(find.text('+325 coins'), findsOneWidget);
      expect(find.text('Coins Earned'), findsOneWidget);
    });

    testWidgets('displays estimated delivery time', (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      expect(find.text('Estimated Delivery'), findsOneWidget);
      expect(find.text('30-45 minutes'), findsOneWidget);
    });

    testWidgets('displays Track Order and Back to Home buttons',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      expect(find.text('Track Order'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('shows fallback UI when no data is passed', (tester) async {
      await tester.pumpWidget(buildTestWidget(data: null));
      await tester.pumpAndSettle();

      // Fallback message
      expect(find.text('Your order has been confirmed!'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('Back to Home button navigates to home', (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Track Order button navigates to order detail',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(data: testData));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Track Order'));
      await tester.pumpAndSettle();

      expect(find.text('Order abc12345xyz'), findsOneWidget);
    });
  });
}
