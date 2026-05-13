import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A shimmer loading placeholder that shows a pulsing gradient animation.
///
/// Use this as a skeleton loader while data is being fetched.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: const [
                AppColors.surfaceGrey,
                AppColors.white,
                AppColors.surfaceGrey,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A shimmer loading skeleton for a meal card in the catalog grid.
class MealCardSkeleton extends StatelessWidget {
  const MealCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: double.infinity, height: 100, borderRadius: 8),
            const SizedBox(height: 8),
            const ShimmerBox(width: 120, height: 14),
            const SizedBox(height: 6),
            const ShimmerBox(width: 80, height: 12),
            const Spacer(),
            const ShimmerBox(width: 60, height: 16),
          ],
        ),
      ),
    );
  }
}

/// A shimmer loading skeleton for a list tile.
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const ShimmerBox(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 150, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 100, height: 12),
              ],
            ),
          ),
          const ShimmerBox(width: 40, height: 14),
        ],
      ),
    );
  }
}

/// Shows a grid of meal card skeletons while the catalog loads.
class CatalogLoadingSkeleton extends StatelessWidget {
  const CatalogLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const MealCardSkeleton(),
    );
  }
}
