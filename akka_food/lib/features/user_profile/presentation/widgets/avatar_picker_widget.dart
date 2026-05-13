import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/avatar_bank.dart';
import '../notifiers/profile_notifier.dart';

/// A reusable widget that displays the user's avatar and lets them
/// choose from a bank of pre-made avatars.
///
/// Tapping opens the [AvatarBankSheet] bottom sheet where users can
/// select an emoji avatar. The selection is saved to Firestore.
class AvatarPickerWidget extends ConsumerWidget {
  const AvatarPickerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final isLoading = profileAsync.isLoading;
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;
    final displayName = profileAsync.valueOrNull?.displayName ?? '';

    return GestureDetector(
      onTap: isLoading ? null : () => _showAvatarBank(context, ref, avatarUrl),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Avatar display
          AvatarBankDisplay(
            avatarUrl: avatarUrl,
            radius: 52,
            displayName: displayName,
          ),

          // Edit icon overlay
          if (!isLoading)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.edit,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),

          // Loading overlay
          if (isLoading)
            CircleAvatar(
              radius: 52,
              backgroundColor: Colors.black.withValues(alpha: 0.3),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAvatarBank(
    BuildContext context,
    WidgetRef ref,
    String? currentAvatarUrl,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AvatarBankSheet(selectedUrl: currentAvatarUrl),
    );

    if (result == null) return;

    // Save the selected avatar to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final avatarValue = result == 'remove' ? null : result;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'avatarUrl': avatarValue});

      // Invalidate the profile to refresh
      ref.invalidate(profileNotifierProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
