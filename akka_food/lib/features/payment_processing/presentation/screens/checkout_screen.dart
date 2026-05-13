import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akka_food/core/theme/app_theme.dart';
import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/cart_summary.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/payment_processing/domain/entities/payment_request.dart';
import 'package:akka_food/features/payment_processing/presentation/notifiers/payment_notifier.dart';

// ---------------------------------------------------------------------------
// CheckoutScreen
// ---------------------------------------------------------------------------

/// Displays the order summary, phone number input, and "Pay with Orange Money"
/// button.
///
/// Receives the [Cart] via GoRouter's `extra` parameter (passed from
/// [CartScreen] on checkout).
///
/// Watches [paymentNotifierProvider] to react to state changes:
/// - [PaymentUIState.initiating] — shows loading indicator on the button
/// - [PaymentUIState.processing] — navigates to PaymentProcessingScreen
///
/// Satisfies:
/// - Req 1 AC1: User confirms checkout with non-zero Total
/// - Req 1 AC2: Display Orange Money payment confirmation
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// Whether we've already navigated to the processing screen.
  /// Prevents duplicate navigation from multiple state emissions.
  bool _hasNavigatedToProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Phone validation
  // ---------------------------------------------------------------------------

  /// Validates a Mali Orange Money phone number.
  ///
  /// Accepted formats:
  /// - 8 digits (e.g. "76123456")
  /// - +223 followed by 8 digits (e.g. "+22376123456")
  /// - 223 followed by 8 digits (e.g. "22376123456")
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-]'), '');

    // Match: optional +223 or 223 prefix, then exactly 8 digits
    final regex = RegExp(r'^(\+?223)?[0-9]{8}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid Mali phone number (8 digits)';
    }

    return null;
  }

  /// Normalizes the phone number to include the +223 prefix.
  String _normalizePhoneNumber(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.startsWith('+223')) {
      return cleaned;
    } else if (cleaned.startsWith('223')) {
      return '+$cleaned';
    } else {
      return '+223$cleaned';
    }
  }

  // ---------------------------------------------------------------------------
  // Payment initiation
  // ---------------------------------------------------------------------------

  /// Initiates the payment flow via [PaymentNotifier].
  Future<void> _onPayTapped(Cart cart) async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = _normalizePhoneNumber(_phoneController.text);

    final cartSummary = CartSummary(
      items: cart.items,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      discount: cart.discount,
      total: cart.total,
      redeemedCoins: cart.redeemedCoins,
      deliveryOption: cart.deliveryOption,
      deliveryAddress: cart.selectedAddress,
    );

    final request = PaymentRequest(
      cartSummary: cartSummary,
      phoneNumber: phoneNumber,
    );

    await ref.read(paymentNotifierProvider.notifier).initiatePayment(request);
  }

  // ---------------------------------------------------------------------------
  // Format helpers
  // ---------------------------------------------------------------------------

  /// Formats an amount in XOF with thousands separator.
  /// e.g. 2500.0 → "2,500 XOF"
  String _formatXOF(double amount) {
    final intAmount = amount.round();
    final formatted = intAmount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted XOF';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cart = GoRouterState.of(context).extra as Cart?;

    if (cart == null || cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paiement')),
        body: const Center(
          child: Text('Aucun article à commander. Ajoutez des plats au panier.'),
        ),
      );
    }

    // Watch payment state for navigation and button state.
    final paymentState = ref.watch(paymentNotifierProvider);

    // Listen for state transitions to navigate to processing screen.
    ref.listen<AsyncValue<PaymentUIState>>(
      paymentNotifierProvider,
      (previous, next) {
        final state = next.valueOrNull;
        if (state == PaymentUIState.processing && !_hasNavigatedToProcessing) {
          _hasNavigatedToProcessing = true;
          context.push('/payment/processing', extra: cart);
        }
      },
    );

    final isInitiating =
        paymentState.valueOrNull == PaymentUIState.initiating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order Summary Section ──────────────────────────────
                    _buildOrderSummarySection(context, cart),

                    const SizedBox(height: 24),

                    // ── Phone Number Input ─────────────────────────────────
                    _buildPhoneInputSection(context),
                  ],
                ),
              ),
            ),

            // ── Pay Button ──────────────────────────────────────────────
            _buildPayButton(context, cart, isInitiating),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Order Summary Section
  // ---------------------------------------------------------------------------

  Widget _buildOrderSummarySection(BuildContext context, Cart cart) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résumé de la commande',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Item list
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.mealName,
                            style: theme.textTheme.bodyMedium,
                            semanticsLabel:
                                '${item.mealName}, quantity ${item.quantity}',
                          ),
                        ),
                        Text(
                          '×${item.quantity}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _formatXOF(item.lineTotal),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),

                // Subtotal
                _buildSummaryRow(
                  context,
                  label: 'Sous-total',
                  value: _formatXOF(cart.subtotal),
                ),

                // Delivery fee
                if (cart.deliveryFee > 0)
                  _buildSummaryRow(
                    context,
                    label: 'Frais de livraison',
                    value: _formatXOF(cart.deliveryFee),
                  ),

                // Discount (coins)
                if (cart.discount > 0)
                  _buildSummaryRow(
                    context,
                    label: 'Réduction coins',
                    value: '-${_formatXOF(cart.discount)}',
                    isDiscount: true,
                  ),

                const Divider(height: 24),

                // Total
                _buildSummaryRow(
                  context,
                  label: 'Total',
                  value: _formatXOF(cart.total),
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a row in the summary section (subtotal, delivery, discount, total).
  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isBold = false,
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);
    final textStyle = isBold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(
            value,
            style: textStyle?.copyWith(
              color: isDiscount ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone Input Section
  // ---------------------------------------------------------------------------

  Widget _buildPhoneInputSection(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orange Money Phone Number',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the phone number linked to your Orange Money account.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              LengthLimitingTextInputFormatter(15),
            ],
            decoration: const InputDecoration(
              prefixText: '+223 ',
              hintText: '76 XX XX XX',
              labelText: 'Phone number',
              border: OutlineInputBorder(),
              helperText: '8-digit Mali phone number',
            ),
            validator: _validatePhoneNumber,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pay Button
  // ---------------------------------------------------------------------------

  Widget _buildPayButton(BuildContext context, Cart cart, bool isInitiating) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // ── Test Mode Button (bypasses payment) ─────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isInitiating ? null : () => _createTestOrder(cart),
              icon: const Icon(Icons.flash_on, size: 20),
              label: const Text(
                'Commander (Mode Test)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Real Payment Button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: isInitiating ? null : () => _onPayTapped(cart),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                foregroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isInitiating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      'Payer ${_formatXOF(cart.total)} (Orange Money)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Test Mode — Create order directly in Firestore
  // ---------------------------------------------------------------------------

  Future<void> _createTestOrder(Cart cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }

    // Show loading
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // Get user's display name from Firestore profile (more up-to-date than Auth)
      String customerName = user.displayName ?? user.email ?? 'Client';
      try {
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final firestoreName = userDoc.data()!['displayName'] as String?;
          if (firestoreName != null && firestoreName.isNotEmpty) {
            customerName = firestoreName;
          }
        }
      } catch (_) {
        // Use Auth name as fallback
      }

      // Create order document
      final orderData = <String, dynamic>{
        'uid': user.uid,
        'userDisplayName': customerName,
        'userPhone': user.phoneNumber,
        'status': 'confirmed',
        'items': cart.items.map((item) => {
          'mealId': item.mealId,
          'name': item.mealName,
          'mealName': item.mealName,
          'mealImageUrl': item.mealImageUrl,
          'unitPrice': item.unitPrice,
          'quantity': item.quantity,
          'lineTotal': item.lineTotal,
        }).toList(),
        'subtotal': cart.subtotal,
        'deliveryFee': cart.deliveryFee,
        'discount': cart.discount,
        'total': cart.total,
        'totalAmount': cart.total,
        'redeemedCoins': cart.redeemedCoins,
        'deliveryOption': cart.deliveryOption.name,
        'deliveryAddress': cart.selectedAddress != null
            ? {
                'label': cart.selectedAddress!.label,
                'streetAddress': cart.selectedAddress!.streetAddress,
                'city': cart.selectedAddress!.city,
              }
            : null,
        'paymentMethod': 'test_mode',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final orderRef = await firestore.collection('orders').add(orderData);

      // Credit 5% coins (loyalty)
      final coinsEarned = (cart.total * 0.05).round();
      if (coinsEarned > 0) {
        await firestore
            .collection('users')
            .doc(user.uid)
            .collection('coinTransactions')
            .add({
          'amount': coinsEarned,
          'type': 'credit',
          'reason': 'Commande #${orderRef.id.substring(0, 8)}',
          'orderId': orderRef.id,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update user's coinBalance field
        await firestore.collection('users').doc(user.uid).update({
          'coinBalance': FieldValue.increment(coinsEarned),
        });
      }

      // Update leaderboard — add/update user's score in all_time document
      try {
        final leaderboardRef = firestore.collection('leaderboard').doc('all_time');
        final leaderboardDoc = await leaderboardRef.get();
        final currentEntries = (leaderboardDoc.data()?['entries'] as List<dynamic>?) ?? [];
        
        // Find existing entry or create new one
        final existingIndex = currentEntries.indexWhere(
          (e) => (e as Map<String, dynamic>)['uid'] == user.uid,
        );
        
        final newScore = (coinsEarned > 0 ? coinsEarned : cart.total.round());
        
        if (existingIndex >= 0) {
          final existing = currentEntries[existingIndex] as Map<String, dynamic>;
          currentEntries[existingIndex] = {
            ...existing,
            'score': ((existing['score'] as num?)?.toInt() ?? 0) + newScore,
            'displayName': customerName,
          };
        } else {
          currentEntries.add({
            'uid': user.uid,
            'displayName': customerName,
            'avatarUrl': null,
            'score': newScore,
          });
        }
        
        // Sort by score descending and keep top 100
        currentEntries.sort((a, b) => 
          ((b as Map<String, dynamic>)['score'] as num).compareTo(
            (a as Map<String, dynamic>)['score'] as num));
        final top100 = currentEntries.take(100).toList();
        
        await leaderboardRef.set({
          'entries': top100,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Leaderboard update is non-critical
      }

      // Clear the cart
      ref.read(cartNotifierProvider.notifier).clearCart();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      // Navigate to order tracking
      context.go('/orders/${orderRef.id}/tracking');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
