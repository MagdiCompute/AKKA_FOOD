import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// An animated "Add to Cart" button with a bounce effect on tap.
///
/// Shows a brief scale animation when pressed, then calls [onPressed].
/// Displays a checkmark icon briefly after being tapped to confirm the action.
class AnimatedAddToCartButton extends StatefulWidget {
  const AnimatedAddToCartButton({
    super.key,
    required this.onPressed,
    this.label = 'Ajouter au panier',
    this.enabled = true,
    this.disabledLabel = 'Indisponible',
  });

  final VoidCallback? onPressed;
  final String label;
  final String disabledLabel;
  final bool enabled;

  @override
  State<AnimatedAddToCartButton> createState() =>
      _AnimatedAddToCartButtonState();
}

class _AnimatedAddToCartButtonState extends State<AnimatedAddToCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || widget.onPressed == null) return;

    // Bounce animation
    await _controller.forward();
    await _controller.reverse();

    // Show checkmark
    setState(() => _showCheck = true);
    widget.onPressed!();

    // Reset after delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showCheck = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: widget.enabled ? _handleTap : null,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showCheck
                    ? const Icon(Icons.check_circle, key: ValueKey('check'))
                    : const Icon(Icons.shopping_cart_outlined,
                        key: ValueKey('cart')),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _showCheck
                      ? 'Ajouté !'
                      : (widget.enabled ? widget.label : widget.disabledLabel),
                  key: ValueKey(_showCheck),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _showCheck
                    ? Colors.green
                    : (widget.enabled
                        ? AppColors.primaryBlue
                        : null),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
