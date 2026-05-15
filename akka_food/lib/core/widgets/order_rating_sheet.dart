import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A bottom sheet that lets users rate their order after delivery.
///
/// Rates three aspects:
/// 1. Overall order experience (1-5 stars)
/// 2. Each meal individually (1-5 stars)
/// 3. Delivery service (1-5 stars)
///
/// Also allows a text comment. Saves ratings to Firestore.
class OrderRatingSheet extends StatefulWidget {
  const OrderRatingSheet({
    super.key,
    required this.orderId,
    required this.mealNames,
  });

  final String orderId;
  final List<String> mealNames;

  @override
  State<OrderRatingSheet> createState() => _OrderRatingSheetState();
}

class _OrderRatingSheetState extends State<OrderRatingSheet> {
  int _overallRating = 0;
  int _deliveryRating = 0;
  final Map<int, int> _mealRatings = {};
  final _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez noter votre commande')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ratingData = <String, dynamic>{
        'orderId': widget.orderId,
        'uid': user.uid,
        'userName': user.displayName ?? 'Utilisateur',
        'overallRating': _overallRating,
        'deliveryRating': _deliveryRating > 0 ? _deliveryRating : null,
        'mealRatings': _mealRatings.map((index, rating) => MapEntry(
              widget.mealNames[index],
              rating,
            )),
        'comment': _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to /ratings collection
      await FirebaseFirestore.instance.collection('ratings').add(ratingData);

      // Also update the order document with the rating
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'rating': _overallRating,
        'isRated': true,
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre avis ! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Noter votre commande',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // ── Overall rating ─────────────────────────────────────
                  _RatingSection(
                    title: 'Expérience globale',
                    subtitle: 'Comment était votre commande ?',
                    icon: Icons.star_rounded,
                    rating: _overallRating,
                    onRatingChanged: (r) => setState(() => _overallRating = r),
                  ),
                  const SizedBox(height: 20),

                  // ── Delivery rating ────────────────────────────────────
                  _RatingSection(
                    title: 'Service de livraison',
                    subtitle: 'Rapidité et qualité de la livraison',
                    icon: Icons.delivery_dining,
                    rating: _deliveryRating,
                    onRatingChanged: (r) => setState(() => _deliveryRating = r),
                  ),
                  const SizedBox(height: 20),

                  // ── Meal ratings ───────────────────────────────────────
                  if (widget.mealNames.isNotEmpty) ...[
                    Text(
                      'Noter les plats',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.mealNames.asMap().entries.map((entry) {
                      final index = entry.key;
                      final name = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _StarRow(
                              rating: _mealRatings[index] ?? 0,
                              size: 24,
                              onRatingChanged: (r) =>
                                  setState(() => _mealRatings[index] = r),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),

                  // ── Comment ────────────────────────────────────────────
                  Text(
                    'Commentaire (optionnel)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Partagez votre expérience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Submit button ─────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton(
                          onPressed: _submit,
                          child: const Text('Envoyer mon avis'),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _RatingSection
// ---------------------------------------------------------------------------

class _RatingSection extends StatelessWidget {
  const _RatingSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rating,
    required this.onRatingChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 8),
        _StarRow(rating: rating, size: 36, onRatingChanged: onRatingChanged),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _StarRow
// ---------------------------------------------------------------------------

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.rating,
    required this.size,
    required this.onRatingChanged,
  });

  final int rating;
  final double size;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: isFilled ? Colors.amber : Colors.grey.shade400,
            ),
          ),
        );
      }),
    );
  }
}
