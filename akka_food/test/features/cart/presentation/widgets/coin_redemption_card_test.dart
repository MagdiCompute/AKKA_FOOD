import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/repositories/i_cart_repository.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/cart/presentation/widgets/coin_redemption_card.dart';
import 'package:akka_food/features/coins/domain/entities/coin_balance.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeCartRepository implements ICartRepository {
  Cart? savedCart;
  Cart? cartToLoad;
  Cart? recheckResult;

  @override
  Future<void> save(Cart cart) async {
    savedCart = cart;
  }

  @override
  Future<Cart?> load() async => cartToLoad;

  @override
  Future<void> clear() async {
    savedCart = null;
  }

  @override
  Future<Cart> recheckAvailability(Cart cart) async {
    return recheckResult ?? cart;
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Creates a test [Meal] with sensible defaults.
Meal makeMeal({
  String id = 'meal-1',
  String name = 'Test Meal',
  double price = 3000.0,
  bool isAvailable = true,
}) =>
    Meal(
      id: id,
      name: name,
      description: 'A test meal',
      price: price,
      categoryId: 'cat-1',
      imageUrls: const ['https://example.com/img.jpg'],
      isAvailable: isAvailable,
      isFeatured: false,
      featuredOrder: 0,
      nutritionalInfo: null,
      dietaryTags: const [],
      popularityScore: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

/// Builds a [ProviderScope]-wrapped widget with the [CoinRedemptionCard],
/// overriding the coin balance and cart repository providers.
///
/// Uses [_CartPopulator] to add a meal to the cart so the subtotal is non-zero
/// when [addMealToCart] is true.
Widget buildTestWidget({
  required int coinBalance,
  bool addMealToCart = false,
  double mealPrice = 3000.0,
}) {
  final repo = FakeCartRepository();

  return ProviderScope(
    overrides: [
      coinBalanceProvider.overrideWith(
        (ref) => CoinBalance.fromTotal(coinBalance),
      ),
      cartRepositoryProvider.overrideWith((_) async => repo),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: addMealToCart
            ? _CartPopulator(mealPrice: mealPrice)
            : const CoinRedemptionCard(),
      ),
    ),
  );
}

/// A helper widget that adds a meal to the cart via [CartNotifier.addItem]
/// after the first frame, then renders the [CoinRedemptionCard].
class _CartPopulator extends ConsumerStatefulWidget {
  const _CartPopulator({required this.mealPrice});
  final double mealPrice;

  @override
  ConsumerState<_CartPopulator> createState() => _CartPopulatorState();
}

class _CartPopulatorState extends ConsumerState<_CartPopulator> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartNotifierProvider.notifier).addItem(
            makeMeal(price: widget.mealPrice),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const CoinRedemptionCard();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CoinRedemptionCard', () {
    // -----------------------------------------------------------------------
    // Visibility tests (Req 2 AC1)
    // -----------------------------------------------------------------------

    testWidgets('is hidden when coin balance < 1000', (tester) async {
      await tester.pumpWidget(buildTestWidget(coinBalance: 999));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
      expect(find.text('Redeem Coins'), findsNothing);
    });

    testWidgets('is hidden when coin balance is 0', (tester) async {
      await tester.pumpWidget(buildTestWidget(coinBalance: 0));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('is visible when coin balance == 1000', (tester) async {
      await tester.pumpWidget(buildTestWidget(coinBalance: 1000));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Redeem Coins'), findsOneWidget);
    });

    testWidgets('is visible when coin balance > 1000', (tester) async {
      await tester.pumpWidget(buildTestWidget(coinBalance: 5000));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Redeem Coins'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Display tests
    // -----------------------------------------------------------------------

    testWidgets('displays the user coin balance text', (tester) async {
      await tester.pumpWidget(buildTestWidget(coinBalance: 2500));
      await tester.pumpAndSettle();

      expect(find.text('You have 2500 coins'), findsOneWidget);
    });

    testWidgets('shows coin icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(coinBalance: 1000));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('shows correct redeemable amount (Save X XOF)',
        (tester) async {
      // Balance 2500, meal price 3000:
      // maxByBalance = (2500 ~/ 1000) * 1000 = 2000
      // maxBySubtotal = 3000
      // min(2000, 3000) = 2000 → (2000 ~/ 1000) * 1000 = 2000
      await tester.pumpWidget(
        buildTestWidget(coinBalance: 2500, addMealToCart: true, mealPrice: 3000),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save 2000 XOF'), findsOneWidget);
    });

    testWidgets(
        'redeemable amount is capped by subtotal when subtotal < balance',
        (tester) async {
      // Balance 5000, meal price 1500:
      // maxByBalance = (5000 ~/ 1000) * 1000 = 5000
      // maxBySubtotal = 1500
      // min(5000, 1500) = 1500 → (1500 ~/ 1000) * 1000 = 1000
      await tester.pumpWidget(
        buildTestWidget(coinBalance: 5000, addMealToCart: true, mealPrice: 1500),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save 1000 XOF'), findsOneWidget);
    });

    testWidgets('does not show "Save X XOF" when redeemable is 0',
        (tester) async {
      // Balance >= 1000 but subtotal = 0 (empty cart) → redeemable = 0
      await tester.pumpWidget(buildTestWidget(coinBalance: 2000));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.textContaining('Save'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Switch behavior tests (Req 2 AC2)
    // -----------------------------------------------------------------------

    testWidgets('switch is disabled when redeemable amount is 0',
        (tester) async {
      // Balance >= 1000 but subtotal = 0 → redeemable = 0 → switch disabled
      await tester.pumpWidget(buildTestWidget(coinBalance: 2000));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets('switch is enabled when redeemable amount > 0',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(coinBalance: 2000, addMealToCart: true, mealPrice: 3000),
      );
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNotNull);
    });

    testWidgets('toggle on applies coin discount', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(coinBalance: 3000, addMealToCart: true, mealPrice: 5000),
      );
      await tester.pumpAndSettle();

      // Switch should be off initially
      Switch switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      // Toggle on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Switch should now be on
      switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('toggle off removes coin discount', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(coinBalance: 3000, addMealToCart: true, mealPrice: 5000),
      );
      await tester.pumpAndSettle();

      // Toggle on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify on
      Switch switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);

      // Toggle off
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify off
      switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });
  });
}
