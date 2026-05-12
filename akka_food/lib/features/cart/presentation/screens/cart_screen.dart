import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akka_food/core/router/app_router.dart';
import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/domain/entities/cart_validation_result.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/cart/presentation/widgets/address_selector.dart';
import 'package:akka_food/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:akka_food/features/cart/presentation/widgets/cart_summary_card.dart';
import 'package:akka_food/features/cart/presentation/widgets/coin_redemption_card.dart';
import 'package:akka_food/features/cart/presentation/widgets/delivery_toggle.dart';

/// The main Cart screen.
///
/// Displays:
/// - An empty-state view when the cart has no items (Req 2.3).
/// - A scrollable list of [CartItemTile] placeholders, a [DeliveryToggle],
///   an address selector section (when delivery is selected),
///   a [CoinRedemptionCard] placeholder, and a [CartSummaryCard] placeholder
///   when the cart has items (Req 2.1, 2.2).
/// - A sticky "Checkout" button that validates the cart and navigates to the
///   payment screen on success (Req 8.3).
/// - An AppBar with title "My Cart" and a clear-cart icon button (Req 5.1, 5.2).
///
/// Placeholder widgets for [CartItemTile], [DeliveryToggle],
/// [CoinRedemptionCard], and [CartSummaryCard] will be replaced in tasks
/// 4.2–4.6.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  /// Whether a checkout validation is in progress.
  bool _isCheckingOut = false;

  // ---------------------------------------------------------------------------
  // Checkout
  // ---------------------------------------------------------------------------

  /// Validates the cart and navigates to the payment screen on success.
  ///
  /// Shows a [SnackBar] with the appropriate error message when validation
  /// fails (Req 8.1, 8.2, 8.4).
  Future<void> _onCheckoutTapped() async {
    if (_isCheckingOut) return;

    setState(() => _isCheckingOut = true);

    try {
      final result = await ref
          .read(cartNotifierProvider.notifier)
          .validateForCheckout();

      if (!mounted) return;

      if (result.isValid) {
        // Req 8.3 — navigate to payment screen, passing the cart as extra.
        final cart = ref.read(cartNotifierProvider);
        context.push(AppRoutes.payment, extra: cart);
      } else {
        _showValidationError(result);
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  /// Shows a [SnackBar] describing the first validation failure.
  void _showValidationError(CartValidationResult result) {
    String message;

    if (result.emptyCart) {
      message = 'Your cart is empty. Add some meals first.';
    } else if (result.missingDeliveryAddress) {
      message = 'Please select a delivery address before checking out.';
    } else if (result.unavailableMealIds.isNotEmpty) {
      final count = result.unavailableMealIds.length;
      message = count == 1
          ? 'One item in your cart is no longer available. Please remove it.'
          : '$count items in your cart are no longer available. Please remove them.';
    } else {
      message = 'Unable to proceed to checkout. Please review your cart.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Clear cart
  // ---------------------------------------------------------------------------

  /// Shows a confirmation dialog and clears the cart if confirmed (Req 5.2).
  Future<void> _onClearCartTapped() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'All items will be removed from your cart. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(cartNotifierProvider.notifier).clearCart();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);

    return Scaffold(
      appBar: _buildAppBar(context, cart),
      body: cart.items.isEmpty
          ? _buildEmptyState(context)
          : _buildCartContent(context, cart),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, Cart cart) {
    return AppBar(
      title: const Text('My Cart'),
      actions: [
        if (cart.items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear cart',
            onPressed: _onClearCartTapped,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state (Req 2.3)
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some delicious meals to get started.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.catalog),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Menu'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cart content (Req 2.1, 2.2)
  // ---------------------------------------------------------------------------

  Widget _buildCartContent(BuildContext context, Cart cart) {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Cart items list (Req 2.1) ──────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => CartItemTile(
                      item: cart.items[index],
                    ),
                    childCount: cart.items.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Delivery toggle (Req 6.1) ─────────────────────────────
              const SliverToBoxAdapter(
                child: DeliveryToggle(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Address selector (shown when delivery is selected) ─────
              if (cart.deliveryOption == DeliveryOption.delivery)
                const SliverToBoxAdapter(
                  child: AddressSelector(),
                ),

              // ── Inline error: delivery selected but no address (Req 8.2) ──
              if (cart.deliveryOption == DeliveryOption.delivery &&
                  cart.selectedAddress == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Please select a delivery address',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.error,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (cart.deliveryOption == DeliveryOption.delivery)
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Coin redemption card (Req 7.1) ───────────────────────
              const SliverToBoxAdapter(
                child: CoinRedemptionCard(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Cart summary card (Req 2.2) ───────────────────────────
              SliverToBoxAdapter(
                child: CartSummaryCard(cart: cart),
              ),

              // Bottom padding so content isn't hidden behind the button
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),

        // ── Sticky checkout button ─────────────────────────────────────
        _buildCheckoutButton(context, cart),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Checkout button
  // ---------------------------------------------------------------------------

  Widget _buildCheckoutButton(BuildContext context, Cart cart) {
    // Req 8.4 — block checkout when unavailable items present.
    final hasUnavailableItems = cart.items.any((item) => !item.isAvailable);
    // Req 8.2 — block checkout when delivery selected but no address.
    final missingAddress = cart.deliveryOption == DeliveryOption.delivery &&
        cart.selectedAddress == null;
    final canCheckout = !_isCheckingOut && !hasUnavailableItems && !missingAddress;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: canCheckout ? _onCheckoutTapped : null,
            child: _isCheckingOut
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
